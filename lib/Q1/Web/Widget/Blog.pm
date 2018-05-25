package Q1::Web::Widget::Blog;

use utf8;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Data::Printer;
use Carp;
use Q1::Utils::ConfigLoader;
use DateTime::Format::Strptime;
use Q1::Moose::Widget;
use Try::Tiny;
use HTML::Strip;
use List::Util qw/any/;

extends 'Q1::Web::Widget';



# parent attributes
has '+template'       => ( default => 'widget/blog.tt' );
has '+backend_view'   => ( default => 'blogEditor' );

# attributes
# has 'api', is => 'ro', isa => 'Object', lazy_build => 1;


# config
has_config 'author_info',         isa => 'ArrayRef', predicate => 'has_author_info'; # TODO: standardize this, or give a good default
has_config 'page_path',           isa => 'Str', default => ''; # TODO: introspect this value from the SiteMap or transform into a param
has_config 'limit',               isa => 'Int', default => 10, is_parameter => 1;
# has_config 'feed_title',          isa => 'Str';
# has_config 'feed_description',    isa => 'Str', default => '';
# has_config 'feed_full_content',   isa => 'Bool', default => 0;
has_config 'render_similar',      isa => 'Bool', default => 0, is_parameter => 1;

has_config 'exclude_current_post', isa => 'Bool', default => 0, is_parameter => 1;
has_config 'exclude_posts',       isa => 'Str';

has_config 'tag_page_title',      isa => 'Str', default => 'Posts com a tag "{name}"';
has_config 'category_page_title', isa => 'Str', default => 'Posts na categoria "{name}"';
has_config 'og_image_size',       isa => 'Str', default => '250x250';
has_config 'og_image_crop',       isa => 'Bool', default => 1;

has_config 'disable_cover',       isa => 'Bool', default => 0;
has_config 'cover_ratio',        isa => 'Num', default => 1.33;
has_config 'url_format', default => '/year/month/day/permalink', is_parameter => 1;

# arguments
has_config 'noarguments', lazy => 1, default => sub {
    my $self = shift;
    ($self->tx->stash->{widget_args} || '') ne $self->name;
};

our @ARGUMENTS = qw/ id year month day permalink category tag /;
for my $attr (@ARGUMENTS) {
    has_argument($attr, lazy => 1, is_parameter => 1, default => sub {
        my $self = shift;
        $self->noarguments ? undef : $self->tx->stash->{$attr};
    })
}

# params
our @PARAMETERS = qw/ page start include_unpublished feed token search /;
for my $attr (@PARAMETERS) {
    has_param($attr, lazy => 1,  default => sub { shift->tx->param($attr) });
}


sub routes {
    my $year        = qr/\d{4}/;
    my $month       = qr/\d\d?/;
    my $day         = $month;
    my $permalink   = qr/[a-z0-9_-]+/;
    my $contraints = [id => qr/\d+/, year => $year, month => $month, day => $day, permalink => $permalink, tag => $permalink];
    [
        ['id/:id', [id => qr/\d+/]],
        [':year', [year => $year]],
        [':year/:month', [year => $year, month => $month]],
        [':year/:month/:day', [year => $year, month => $month, day => $day]],
        [':year/:month/:day/:permalink', [year => $year, month => $month, day => $day, permalink => $permalink]],
        [':year/:month/:permalink', [year => $year, month => $month, permalink => $permalink]],
        [':year/:permalink', $contraints],
        [':permalink', [permalink => $permalink]],
        ['tag/:tag', [tag => $permalink]],
        ['category/:category', [category => $permalink]],
    ]
}


sub api {
    my $self = shift;
    $self->tx->api('Blog', { widget => $self });
}


sub load_fixtures {
    my ($self) = @_;

    my $app = $self->app;

    my $loader = Q1::Utils::ConfigLoader->new;

    # find fixture file
    my $fixture_file;
    foreach my $file (
        $self->tx->app_instance->path_to('fixtures', 'widget', $self->name, 'fixture.yml'),
        $app->path_to('share/fixtures/widget/blog/fixture.yml')
    ) {
        if (-e $file) {
            $fixture_file = $file;
            last;
        }
    }

    # not found
    unless ($fixture_file) {
        $app->log->debug("No fixture found for blog widget '". $self->name ."'.");
        return;
    }

    # load fixtures
    $app->log->debug("Loading blog '${\ $self->name }' fixtures.");
    my $items = $loader->loadConfigFile($fixture_file) || [];
    my $api = $self->api;

    foreach my $post (@$items) {
        $post->{is_published} = 1 unless defined $post->{is_published};
        $api->create($post);

        my $post = $api->first->{object};
    }

}


sub get_data {
    my ($self, $tx) = @_;

    # prepare api
    my $api = $self->api->with_related('author', $self->has_author_info ? $self->author_info : undef, 1)
                        ->with_related('categories', undef, 1)
                        ->with_related('tags', undef, 1)
                        ->with_url
                        ->limit($self->limit);
    # exclude
    if ($self->exclude_current_post && $tx->stash->{current_blog_post}) {
        $api->where(id => { '!=' => $tx->stash->{current_blog_post}->{id} });
    }

    if ($self->exclude_posts) {
        $api->where(id => { '!=' => [ '-and', split /\s*,\s*/, $self->exclude_posts] });
    }

    # start / limit / page
    if ($self->start) {
        $api->offset($self->start);
    }
    else {
        $api->page($self->page || 1);
    }

    # hide unpublished
    $api->add_list_filter( is_published => 1 )
        unless $self->include_unpublished && $tx->user_exists && $tx->user->check_roles('instance_admin');

    # category
    return $api->list_by_category($self->category, $self)->result
        if $self->category;

    # tag
    return $api->list_by_tag($self->tag)->result
        if $self->tag;


    # permalink
    if ($self->permalink || $self->id) {

        $api->with_similar_posts($self->limit)->with_next->with_previous;
    }

    else {
        $api->search($self->search)
            if $self->search;
    }

    my %args = map { $_ => $self->$_ } grep { defined $self->$_ } @ARGUMENTS;
    my $data = $api->list(\%args)->result;
    $data->{is_permalink_result} = 1
        if $self->id || $self->permalink;

    # author_name
    foreach my $post (@{ $data->{items} }) {
        next unless $post->{author};
        $post->{author_name} = $post->{author}{first_name};
        $post->{author_name} .= " $post->{author}{last_name}"
            if defined $post->{author}{last_name} && length $post->{author}{last_name};
    }

    $data
}


sub list_by_category {
    my ($self, $args) = @_;
    my $res = $self->api->list_by_category($args->{category})->result;
    $self->data($res);
}


sub list_by_tag {
    my ($self, $args) = @_;
    my $res = $self->api->list_by_tag($args->{tag})->result;
    $self->data($res);
}

# sub _generate_feed {
#     my ($self, $params) = @_;
#     my $tx = $self->tx;
#
#     my $feed_type = lc $self->feed eq 'rss' ? 'RSS' : 'Atom';
#     my $feed = XML::Feed->new($feed_type);
#
#     $feed->title( $self->feed_title );
#     $feed->description( $self->feed_description );
#
#     if ($tx) {
#         $feed->link( $tx->uri_for($self->page_path) );
#     }
#
#     my $dt_parser = DateTime::Format::Strptime->new(
#         pattern   => '%F %T',
#         time_zone => 'UTC',
#     );
#
#     # Process the entries
#     foreach my $post ( @{$self->data->{items}} ) {
#         my $feed_entry = XML::Feed::Entry->new($feed_type);
#         $feed_entry->title($post->{title});
#
#         if ($tx) {
#             $feed_entry->link( $post->{url} );
#             $feed_entry->base( $tx->request->base_uri->as_string  );
#         }
#
#         $feed_entry->content( $self->feed_full_content ? $post->{content} : $post->{excerpt} );
#         $feed_entry->summary( $post->{excerpt} );
#
#         $feed_entry->issued( $dt_parser->parse_datetime($post->{created_at}) );
#         $feed_entry->modified( $dt_parser->parse_datetime($post->{updated_at}) );
#
#         $feed->add_entry($feed_entry);
#     }
#
#     $self->content($feed->as_xml);
#     $self->content_type( $feed_type eq 'RSS' ? 'application/rss+xml' : 'application/atom+xml' );
# }


sub get_tag_cloud {
    my ($self, $params) = @_;
    $params ||= {};

    my $tag_api = $self->tx->api('Tag');
    $params->{relationship} = { 'blogpost_tags' => 'blogpost' };
    my $cloud   = $tag_api->generate_tag_cloud($params);

}


sub before_render_page {
    my ($self, $tx) = @_;
    my $data = $self->data;


    # post/tag/category not found
    if ( ($data->{is_permalink_result} && $data->{total} == 0) || $data->{errors} ) {
        $tx->reply->not_found;
        return;
    }

    # is single post
    if ($data->{is_permalink_result}) {

        $tx->properties->set('blog.single');

        # add breadcrumb for blog page
        push @{$tx->stash->{breadcrumbs}}, { title => $tx->stash->{title}, url => $tx->uri_for_page };

        # set page title
        my $post = $data->{items}[0];
        $tx->stash->{title} = $post->{title};

        # single post template
        if ($tx->find_template_file($tx->stash->{template}.'.single')) {
            $tx->stash->{template} .= '.single';
        }

        # stash post
        $tx->stash->{current_blog_post} = $post;

        # metadata
        my $meta = ($tx->stash->{meta} //= {});
        $meta->{author} = $post->{author_name};

        # post opengraph
        $tx->stash->{opengraph} //= {};
        my $og = $tx->stash->{opengraph};

        $og->{type} = 'article';
        $og->{url} = $post->{permalink_url};
        $og->{title} = $post->{title};
        $og->{image} = $tx->uri_for_media($post->{thumbnail_url}, { scale => $self->og_image_size, crop => $self->og_image_crop })
            if $post->{thumbnail_url};

        my $excerpt = $post->{excerpt};
        my $hs = HTML::Strip->new( decode_entities => 1 );
        $og->{description} = $hs->parse( $excerpt );
        $hs->eof;

        $og->{article}{published_time} = $post->{created_at};

        $og->{article}{section} = $post->{categories}[0]{name}
            if scalar @{$post->{categories}} > 0;

        push @{$og->{article}{tag}}, map { $_->{name} } @{$post->{tags}};
    }

    # category page
    if ($self->category) {

        my $category = $self->tx->api('Category', { widget => $self })->find({ slug => $self->category })->first
            or return $tx->reply->not_found;

        $tx->properties->set('blog.category');
        $tx->stash->{title} = $self->category_page_title;
        $tx->stash->{title} =~ s/{\s*name\s*}/${\ $category->name }/;
        $tx->stash->{blog_category} = $category;
        $tx->stash->{template} .= '.category'
            if $tx->find_template_file($tx->stash->{template}.'.category');
    }
    # tag page
    elsif ($self->tag) {

        my $tag = $self->api->_get_tag_api->find({ slug => $self->tag })->first
            or return $tx->reply->not_found;

        $tx->properties->set('blog.tag');
        $tx->stash->{title} = $self->tag_page_title;
        $tx->stash->{title} =~ s/{\s*name\s*}/${\ $tag->name }/;
        $tx->stash->{blog_tag} = $tag;
        $tx->stash->{template} .= '.tag'
            if $tx->find_template_file($tx->stash->{template}.'.tag');
    }

    # search page
    if ($self->search) {
        $tx->properties->set('blog.search');
        $tx->properties->set('blog.search.empty')
            if $data->{total} == 0;
    }
}

sub render_snippet {
    my ($self, $element, $data, $plift) = @_;
    $plift->run_snippet('blog', $element, {
        widget => $self,
        template => $self->template,
        start => $self->start,
        limit => $self->limit,
    });
}








1;
