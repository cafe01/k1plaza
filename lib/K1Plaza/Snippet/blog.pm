package K1Plaza::Snippet::blog;

use Mojo::Base -base;
use Data::Printer;
use Ref::Util qw/ is_blessed_ref /;


has 'name' => 'blog';

has 'engine' => sub { die 'required' };

has 'tx' => sub {
    shift->engine->context->{tx} or die 'undefined engine->tx';
};

has 'widget';


sub process {
    my ($self, $element, $plift, $params) = @_;

    if ($element->children->size == 0 && $self->template) {
        $self->_load_template($self->template, $element);
    }

    my $tx = $self->tx;

    delete @$params{qw/ widget engine name /};
    $self->widget($tx->widget($self->name, $params, $params, $params))
        unless $self->widget;

    my $data = $self->widget->data;
    my $is_permalink_result = $data->{is_permalink_result};

    # bad data, remove element and hope for the best
    return $element->remove unless $data->{items};

    # hide-for-postlist / show-for-postlist
    $element->find($is_permalink_result ? '.show-for-postlist' : '.hide-for-postlist')->remove();

    # find/choose post template
    my $post_tpl;

    if ($is_permalink_result) {
        $post_tpl = $element->find('.blog-post-item')->first;
        $element->find('.blog-postlist-item')->remove;
    }
    else {
        $post_tpl = $element->find('.blog-postlist-item')->first;
        if ($post_tpl->size) {
           $element->find('.blog-post-item')->remove;
        } else {
           $post_tpl = $element->find('.blog-post-item')->first;
        }
    }

    # no template found, use the element itself as template if element is x-tag
    if (!$post_tpl->size && $element->tagname =~ /^x-/) {
        $post_tpl = $element->new('<div/>')->append($element->contents)->insert_after($element);
    }

    # tag / category name
    $element->find('.blog-tag-name')->text($self->widget->tag) if $self->widget->tag;
    $element->find('.blog-category-name')->text($self->widget->category) if $self->widget->category;


    # comments - DEPRECATED
    $post_tpl->find('.blog-post-comment-item')->remove;
    $post_tpl->find('.blog-post-comment-form')->remove;

    # search text
    $element->find('.blog-search-text')->text($self->widget->search)
        if $self->widget->search;

    # default thumb src
    my $post_thumb        = $post_tpl->find('.blog-post-thumb')->first;
    my $default_thumb_src = $post_thumb ? $post_thumb->attr('src') : '';

    # render similar
    die Dumper($data)
        if $data->{errors};

    my @posts = $self->widget->render_similar ? @{$data->{items}[0]{similar_posts}} : @{$data->{items}};

    my $post_schema = {
        title   => { '.blog-post-title' => 'text, @title' },
        url     => { '.blog-post-link' => '@href' },
        title_on_link => { selector => '.blog-post-link', at => '@title', data_key => 'title' },
        excerpt => { '.blog-post-excerpt' => 'html' },
        content => { '.blog-post-content' => 'html' },
        created_at  => '.blog-post-date',
        author_name => '.blog-post-author',
        thumbnail_url => {
            '.blog-post-thumb' => sub {
                my ($img, $url) = @_;

                my $w = $img->attr('data-width')  || $img->attr('width');
                my $h = $img->attr('data-height') || $img->attr('height');
                my $zoom = $img->attr('data-zoom');
                $img->remove_attr('data-width data-height data-zoom');
                my $src = $url ? $tx->uri_for_media($url, { crop => 1, width => $w, height => $h, zoom => $zoom })
                               : $default_thumb_src;

                $img->attr( src => $src );
            }
        },
        _next_title => { '.blog-post-next-title' => 'text, @title' },
        _next_link  => { '.blog-post-next-link' => '@href' },
        _previous_title => { '.blog-post-previous-title' => 'text, @title' },
        _previous_link  => { '.blog-post-previous-link' => '@href' },
    };


    my $dt_parser = DateTime::Format::Strptime->new( pattern => '%F %T', time_zone => 'UTC');

    foreach my $post (@posts) {

        my $tpl = $post_tpl->clone;

        # warn Dumper $post;

        # inflate DateTime
        $post->{created_at} = $dt_parser->parse_datetime($post->{created_at})
            unless is_blessed_ref $post->{created_at};

        # format author name
        $post->{author_name} //= $post->{author}->{first_name} || '';

        # next/previous
        if ($post->{_next}) {
            $post->{_next_title} = $post->{_next}{title};
            $post->{_next_link} = $post->{_next}{url};
        }

        if ($post->{_previous}) {
            $post->{_previous_title} = $post->{_previous}{title};
            $post->{_previous_link} = $post->{_previous}{url};
        }

        # render data
        $tpl->render_data($post_schema, $post);

        # inject editable metadata
        my $key_prefix = join '.', 'blog', $self->widget->name, $post->{id};
        # if ($is_permalink_result) {

            $tpl->find('.blog-post-title')
                ->attr('data-editable', $key_prefix.'.title')
                ->attr('data-ce-tag', 'p')
                ->attr('data-fixture', '');

            $tpl->find('.blog-post-content')->attr('data-editable', $key_prefix.'.content');
        # }


        # tags
        my $tags_tpl = $tpl->find('.blog-post-tag-item');
        $tags_tpl->each(sub {
            my ($i, $el) = @_;
            $self->_render_post_tags($el, $post->{tags});
        });

        # categories
        my $category_tpl = $tpl->find('.blog-post-category-item');
        $category_tpl->each(sub {
            my ($i, $el) = @_;
            $self->_render_post_tags($el, $post->{categories}, 'category');
        });

        # append
        $tpl->insert_before($post_tpl);
    }

    $post_tpl->remove;

    # pager
    $self->_render_pager($element);
}


sub _render_pager {
    my ($self, $pager) = @_;
    my $data = $self->widget->data;
    my $back = $pager->find('.blog-pager-back-link');
    my $prev = $pager->find('.blog-pager-prev-link');
    my $next = $pager->find('.blog-pager-next-link');

    # back
    if ($data->{is_permalink_result}) {
        $back->attr(href => $self->tx->uri_for($self->widget->page_path));
    }
    else {
        $back->remove;
    }

    # prev
    if ($data->{previous_page}) {
        $prev->attr( href => 'link pagina '. $data->{previous_page}); # TODO: use correct url
    }
    else {
        $prev->remove;
    }

    # next
    if ($data->{next_page}) {
        $prev->attr( href => 'link pagina '. $data->{next_page} );
    }
    else {
        $next->remove;
    }

}


sub _render_post_tags {
    my ($self, $template, $tags, $stuff) = @_;
    my $tx = $self->tx;
    $stuff ||= 'tag';
    $tags //= [];

    for (my $i = 0; $i < @$tags; $i++) {
        my $tag = $tags->[$i];
        # my $tpl = $template->clone;

        $template->find('.blog-post-'.$stuff.'-link')
            ->text($tag->{name})
            ->attr('href', $tx->site_url_for("widget-${\ $self->widget->name }-$stuff-$stuff", { $stuff => $tag->{slug} } ))
            ->attr('data-editable', "$stuff.$tag->{id}.name")
            ->attr('data-ce-tag', 'p')
            ->attr('data-fixture', '');

        $template->find('.blog-post-'.$stuff.'-separator, .separator')->remove
            if $i == $#$tags;

        $template->clone->insert_before($template);
        # $tpl->find('.blog-post-'.$stuff.'-link')
        #     ->text($tag->{name})
        #     ->attr(href => $tx->uri_for($self->widget->page_path, [$stuff, $tag->{slug}]));
        #
        # $tpl->find('.blog-post-'.$stuff.'-separator')->remove
        #     if $i == $#$tags;
        #
        # $template->before($tpl->as_html);
    }

    $template->remove;
}


sub _format_datetime {
    my ($value, $pattern, %options) = @_;
    $pattern ||= '%d/%m/%Y %H:%M:%S';

    my $formatter = DateTime::Format::Strptime->new(
        locale    => 'pt_BR',
        pattern   => '%F %T', # 2012-07-24 14:40:09
        time_zone => 'UTC',
    );

    my $dt = try { $formatter->parse_datetime($value) } catch {
        warn "_format_datetime(): error: $_";
    };
    return $value unless $dt;

    return $dt->strftime($pattern);
}


sub _load_template {
    my ($self, $tpl_name, $element) = @_;

    # strip deprecated .html suffix
    $tpl_name =~ s/\.html$//;

    my $dom = $self->engine->load_template($tpl_name);
    $element->html($dom);
}


1;
