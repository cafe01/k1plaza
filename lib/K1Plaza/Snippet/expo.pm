package K1Plaza::Snippet::expo;

use Mojo::Base -base;
use Data::Printer;
use Q1::Web::Template::Plift::Util qw/ render_content /;


has 'engine' => sub { die 'required' };

has 'tx' => sub {
    shift->engine->context->{tx} or die 'undefined engine->tx';
};

has 'name' => 'expo';

has 'widget';


sub process {
    my ($self, $element, $plift, $params) = @_;

    delete @$params{qw/ widget engine name /};
    my $tx = $self->tx;
    $self->widget($tx->widget($self->name, $params, $params, $params))
        unless $self->widget;

    # load template file
    if ($element->children->size == 0 && $self->widget->template) {
        $self->_load_template($self->widget->template, $element);
    }

    my $data = $self->widget->data;
    my $parent = $element->parent;

    $self->_load_element_template($element)
        if $element->children->size == 0;

    # permalink specific
    if ($data->{is_permalink_result}) {

        # show/hide
        $parent->find('.show-for-single-expo')->remove_class('.show-for-single-expo');
        $parent->find('.hide-for-single-expo')->remove;

        # back link
        $element->find('.expo-back-link')->attr( href => $tx->uri_for_page(undef) );

        # expo title
        $element->find('.expo-title')->text($data->{items}[0]{title});

    }
    else {

        # show/hide
        $parent->find('.hide-for-single-expo')->remove_class('.hide-for-single-expo');
        $parent->find('.show-for-single-expo')->remove;

        # back link
        $element->find('.expo-back-link')->remove;

    }
    # expo widget title
    $element->find('.expo-widget-title')->text($self->widget->title);

    # find/choose template
    my $template;

    if ($self->widget->flatten) {
        $template = $element->find('.expo-media-item')->first;
    } elsif ($data->{is_permalink_result}) {
        $template = $element->find('.expo-item')->first;
        $element->find('.expo-list-item')->remove;
    }
    else {
        $template = $element->find('.expo-list-item')->first;
        if ($template->size) {
           $element->find('.expo-item')->remove;
        } else {
           $template = $element->find('.expo-item')->first;
        }
    }

    # no template found
    return $element->html('<div class="template-error" style="color:red; border:2px dashed red;">Erro: template não encontrado.</div>')
        unless $template->size;

    # back link
    $element->find('.expo-back-link')->each(sub{
        $_->attr( href => $tx->uri_for_page(undef));
        $_->remove unless $data->{is_permalink_result};
    });


    # render
    if ($self->widget->flatten) {
        $element->find('.expo-media-count')->text(scalar @{$data->{medias}});
        $self->_render_medias($template, $data->{medias});
    }
    else {
        $element->find('.expo-item-count')->text(scalar @{$data->{items}});
        $self->_render_albums($template, $data->{items});
    }

}


sub _render_albums {
    my ($self, $template, $items) = @_;

    my $tx = $self->tx;
    my $widget_name = $self->widget->name;

    my $i     = $self->widget->shuffle ? $self->widget->start || 0 : 0;
    my $limit = $self->widget->shuffle ? $self->widget->limit || scalar(@$items) : scalar(@$items);


    for (my $count = 1; $count <= $limit && $i <= $#$items; $i++, $count++) {

        my $expo = $items->[$i];
        my $expo_item = $template->clone;

        # data-album-id
        $expo_item->attr( 'data-album-id', $expo->{permalink} );

        # expo-item-n class
        $expo_item->add_class('expo-item-'.$count);

        # TODO indexed data-widget-args-at

        # expo metadata
        foreach my $meta (keys %{$self->widget->metadata || {}}) {
            my $meta_spec = $self->widget->metadata->{$meta};
            $expo_item->find(".expo-meta-$meta")->each(sub{
                $_->attr('data-plift-render-at' => 'html') if $meta_spec->{data_type} eq 'html';
                $_->attr({
                    'data-editable' => join('.', 'expo', $widget_name, $expo->{id}, $meta),
                    'data-ce-tag' => 'p'
                });
                $_->attr('data-fixture', '') unless $meta_spec->{data_type} eq 'html';
                render_content($_, $expo->{$meta})
            });
        }

        # title
        $expo_item->find(".expo-title")->each(sub{
            $_->attr({
                "data-editable" => "expo.".$widget_name.".$expo->{id}.title",
                "data-ce-tag" => "p",
                "data-fixture" => ''
            });
            render_content($_, $expo->{title});
        });

        # expo link
        $expo_item->find('a.expo-link')->attr( href => $expo->{url} );

        # medias
        $expo_item->find('.expo-media-count')->text(scalar @{$expo->{medias}});
        my $media_tpl   = $expo_item->find('.expo-media-item')->first;

        # expo-cover / expo-cover-link
        if ($expo->{cover}) {

            $expo_item->find('.expo-cover')->each(sub{
                $_->attr( src => $tx->uri_for_media($expo->{cover}, {
                    crop   => 1,
                    width  => $_->attr('data-width')  || $_->attr('width'),
                    height => $_->attr('data-height') || $_->attr('height'),
                    zoom   => $_->attr('data-zoom')
                }));
            });

            $expo_item->find('.expo-cover-link')->attr( href => $tx->uri_for_media($expo->{cover}) );
        }

        # render medias
        $self->_render_medias($media_tpl, $expo->{medias});


        if ($expo->{tags}) {

            # has-tag-* classes
            $expo_item->add_class('has-tag-'.$_->{slug})
                foreach (@{$expo->{tags}});

            #
            $expo_item->find('.expo-tag-item')->render_data({
                'name' => '.expo-tag-name'
            }, $expo->{tags});
        }

        $expo_item->insert_before($template);
    }

    $template->remove;
}

sub _render_medias {
    my ($self, $tpl, $medias) = @_;
    my $tx = $self->tx;

    return unless $tpl->size;

    my $start = $self->widget->media_start || 0;
    my $limit = $self->widget->media_limit || scalar @$medias;

    for (my $i = $start, my $count = 1; $i < scalar(@$medias) && $count <= $limit; $i++, $count++) {

        # new element
        my $media = $medias->[$i];
        my $media_item = $tpl->clone;

        # metadata
        $media_item->find('.expo-media-file-name')->text($media->{file_name});

        for my $meta (keys %{$self->widget->media_metadata || {}}) {
            my $meta_spec = $self->widget->media_metadata->{$meta};
            $media_item->find(".expo-media-meta-$meta")->each(sub{
                $_->attr('data-plift-render-at' => 'html') if $meta_spec->{data_type} eq 'html';
                render_content($_, $media->{$meta})
            });
        }

        # link
        $media_item->find('a.expo-media-link')->each(sub {
            my $url = $tx->uri_for_media($media);
            $url->query(download => 1) if defined $_->attr('download');
            $_->attr(href => $url);
        });


        # image
        $media_item->find('.expo-media-image')->each(sub{
            $_->attr(src => $tx->uri_for_media($media, {
                crop   => 1,
                width  => $_->attr('data-width')  || $_->attr('width'),
                height => $_->attr('data-height') || $_->attr('height'),
                zoom   => $_->attr('data-zoom')
            }));
        });

        # columns
        my $columns = $self->widget->columns || 0;
        $media_item->add_class('last-column')
            if $columns > 0 && $count % $columns == 0;

        # album id (when flattened)
        if ($media->{album}) {
            $media_item->attr('data-album-id', $media->{album}->{permalink});
            $media_item->add_class($media->{album}->{permalink});
            $media_item->find('.expo-title')->text($media->{album}->{title});
            $media_item->find('a.expo-link')->attr( href => $media->{album}->{url} );
        }

        $media_item->insert_before($tpl);
    }

    $tpl->remove;
}

sub _load_template {
    my ($self, $tpl_name, $element) = @_;

    # strip deprecated .html suffix
    $tpl_name =~ s/\.html$//;

    my $dom = $self->engine->load_template($tpl_name);
    $element->html($dom);
}

1;
