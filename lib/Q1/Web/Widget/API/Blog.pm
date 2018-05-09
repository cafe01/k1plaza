package Q1::Web::Widget::API::Blog;

use 5.10.0;
use Carp;
use utf8;
use Moose;
use namespace::autoclean;
use Data::Printer;
use DateTime;
use Q1::Utils::HTML::Excerpt;
use Encode qw/ encode_utf8 /;

extends 'DBIx::Class::API';

with 'DBIx::Class::API::Feature::Permalink',
     'Q1::API::Widget::TraitFor::API::BelongsToWidget',
     'DBIx::Class::API::Feature::Tags::HasTags';


has '+flush_object_after_insert', default => 1;

has 'tx', is => 'ro', required => 1;

has '_html_excerpt' => (
    is  => 'ro',
    isa => 'Q1::Utils::HTML::Excerpt',
    default => sub{ Q1::Utils::HTML::Excerpt->new },
    handles => {
        create_excerpt => 'excerpt'
    }
);


__PACKAGE__->config(
    dbic_class         => 'BlogPost',
    sortable_columns   => [qw/ me.created_at /],
    default_list_order => { -desc => 'me.created_at' },
    #return_inflated_columns => [qw/ created_at updated_at /]
    #create_requires => [qw/ title content /]
);


around '_prepare_create_object' => sub {
    my $orig   = shift;
    my $self   = shift;
    my $object = shift;

    # excerpt
    $object->{content} //= "";
    $object->{excerpt} = $self->create_excerpt($object->{content});


    # thumbnail_url
    $object->{has_manual_thumbnail} = 1 if $object->{thumbnail_url};

    if (not $object->{has_manual_thumbnail} and $object->{content} && $object->{content} =~ /<img.*?src="(.*?)".*?>/s) {
        $object->{thumbnail_url} = $1;
    }

    # author
    $object->{author_id} = $self->tx->user->id
        if $self->tx->user_exists;

    $self->$orig($object);
};


around '_update_object' => sub {
    my $orig = shift;
    my $self = shift;
    my ($item) = @_;
    my $object  = $item->{object};


    # thumbnail_url
    $object->has_manual_thumbnail(1) if $object->is_column_changed('thumbnail_url');

    if ($object->is_column_changed('content')) {

        # update excerpt
        $object->excerpt($self->create_excerpt($object->content));

        # update thumbnail_url
        if (not $object->has_manual_thumbnail and $object->content =~ /<img.*?src="(.*?)".*?>/s) {
            $object->thumbnail_url($1);
        }
    }

    if ($object->is_column_changed('is_published') && $object->is_published == 1) {
        $object->created_at(DateTime->now->set_time_zone("UTC"));
    }

    $self->$orig(@_);
};




sub _prepare_related_categories {
    my ($self, $raw) = @_;
    $self->tx->api('Category', { widget => $self->widget })->find_or_create($raw);
}


sub with_next {
    my $self = shift;


    $self->add_object_formatter(sub {
        my ($self, $obj, $formatted) = @_;

        my $result = $self->clone->reset->where(
            created_at => { '<=' => $obj->get_column('created_at') },
            id => {'!=' => $obj->id },
            is_published => 1
            )
            ->order_by({ -desc => 'me.created_at' })
            ->limit(1)
            ->with_url
            ->list
            ->result;

        $formatted->{_next} = $result->{items}->[0];
    });

    $self;
}

sub with_previous {
    my $self = shift;


    $self->add_object_formatter(sub {
        my ($self, $obj, $formatted) = @_;

        my $result = $self->clone->reset->where(
            created_at => { '>=' => $obj->get_column('created_at') },
            id => {'!=' => $obj->id },
            is_published => 1
            )
            ->order_by({ -asc => 'me.created_at' })
            ->limit(1)
            ->with_url
            ->list
            ->result;

        $formatted->{_previous} = $result->{items}->[0];
    });

    $self;
}

sub with_url {
    my ($self) = @_;

    my $widget = $self->widget;
    return $self unless $widget;

    my $tx = $widget->tx;
    my $url_format = $widget->url_format =~ s/^\///r;
    # my $route_name = join '-', 'widget', $widget->name, $url_format =~ s/\//-/gr;
    my $sitemap = $tx->app->routes->find("website");
    my $permalink_route = "widget-${\ $widget->name }-id-id";
    my $slug_route = join '-', 'widget', $widget->name, $url_format =~ s/\//-/gr;

    $self->add_object_formatter(sub {
        my ($self, $obj, $formatted) = @_;
        my $date = $obj->created_at;
        $formatted->{permalink_url} = $tx->site_url_for($permalink_route, { id => $obj->id });
        $formatted->{url} = $tx->site_url_for($slug_route, {
            year => $date->year,
            month => sprintf('%02d', $date->month),
            day => sprintf('%02d', $date->day),
            permalink => $obj->permalink
        });

        $formatted->{permalink_url} = $formatted->{permalink_url}->to_abs->to_string if $formatted->{permalink_url};
        $formatted->{url} = $formatted->{url}->to_abs->to_string if $formatted->{url};
    });

    $self;
}

sub with_similar_posts {
    my ($self, $max) = @_;
    $max ||= 10;

    $self->add_object_formatter(sub {
        my ($self, $obj, $formatted) = @_;

        my @tags = $formatted->{tags} ? map { $_->{id} } @{$formatted->{tags}}
                                      : map { $_->id } $obj->tags;

        my $api = $self->clone->reset;
        my $similar_posts = $api->with_url
                                ->join('blogpost_tags')
                                ->where('id' => { '!=' => $obj->id }, 'blogpost_tags.tag_id' => { -in => \@tags })
                                ->group_by('me.id')
                                ->having('count(me.id) > 0')
                                ->order_by(\'relevancia DESC, me.created_at DESC')
                                ->set_search_attribute('+select' => { count => 'me.id', -as => 'relevancia' })
                                ->limit($max)
                                ->list->result->{items};

        $formatted->{similar_posts} = $similar_posts;
    });

    $self;
}


before 'list' => sub {
    my ($self, $args) = (@_);

    return unless $args;

    # query
    $self->modify_resultset( \[ 'YEAR(me.created_at) = ?', $args->{year} ] )
        if $args->{year};

    $self->modify_resultset( \[ 'MONTH(me.created_at) = ?', $args->{month} ] )
        if $args->{month};

    $self->modify_resultset( \[ 'DAY(me.created_at) = ?', $args->{day} ] )
        if $args->{day};

    $self->modify_resultset({ 'me.permalink' => $args->{permalink}})
        if $args->{permalink};

    $self->modify_resultset({ 'me.id' => $args->{id}})
        if $args->{id};
};

sub search {
    my ($self, $query) = @_;

    my $rs = $self->resultset->search_literal('MATCH (me.title, me.content) AGAINST( ? IN NATURAL LANGUAGE MODE)', $query);
    $self->resultset($rs);
    $self;
}


sub list_by_category {
    my ($self, $name, $widget) = @_;

    my $category = $self->widget->tx->api('Category', { widget => $widget })->find({ slug => $name })->first;

    unless ($category) {
        # NOTE: should this raise an api error?
        $self->push_error('unknown_category');
        $self->tx->log->debug("[Blog API] Invalid category, returning empty result.");
        return $self;
    }

    $self->add_list_filter( 'blogpost_categories.category_id' => $category->id );
    $self->list;
}






1;


__END__

=pod

=head1 NAME

Q1::Core::Multimedia::API::Blog

=head1 DESCRIPTION

=cut
