package Q1::Web::Widget::API::Expo;

use 5.10.0;
use Carp;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use DateTime;


extends 'DBIx::Class::API';

with 'DBIx::Class::API::Feature::Permalink',
     'DBIx::Class::API::Feature::DynaCols',
     'Q1::API::Widget::TraitFor::API::BelongsToWidget',
     'DBIx::Class::API::Feature::Tags::HasTags';


has 'tx', is => 'ro';
has '+dbic_class', default => 'Expo';
has '+dynamic_column_name', default => 'metadata';
has '+sortable_columns', default => sub { [qw/ me.position me.created_at /] };
has '+default_list_order', default => sub { { -asc => 'me.position' } };



before 'list' => sub {
    my ($self, $params) = @_;
    $params = { permalink => $params } unless ref $params;

    # order by
    my $widget_order_by = $self->widget->order_by;
    my $order_by = { -asc  => 'me.position' };
    $order_by    = { -desc => 'me.position' }   if $widget_order_by eq 'position-desc';
    $order_by    = { -desc => 'me.created_at' } if $widget_order_by eq 'created_at-desc';
    $order_by    = { -asc  => 'me.created_at' } if $widget_order_by eq 'created_at-asc';

    # permalink (slug)
    $self->modify_resultset({ 'me.permalink' => $params->{permalink} })->with_next->with_previous
        if $params->{permalink};

    # start, limit
    $self->offset($params->{start}) if $params->{start};
    $self->limit($params->{limit})  if $params->{limit};

    # include_unpublished
    my $tx = $self->tx;
    unless ($params->{include_unpublished} && $tx->is_authenticated && $tx->user->check_roles('instance_admin')) {
        $self->where( is_published => 1 );
    }

    # locale
    if ($params->{locale}) {
        $self->where( locale => $params->{locale} );
    }

    $self->with_url
         ->with_tags
         ->with_medias
         ->order_by($order_by);
};




around [qw/ create update /] => sub {
    my ($orig, $self) = (shift, shift);

    # metadata
    $self->dynamic_columns($self->widget->metadata)
        if $self->widget->has_metadata;

    $self->$orig(@_);
};


sub with_url {
    my ($self) = @_;

    return $self unless $self->widget;
    my $tx = $self->tx;
    my $route = "widget-${\ $self->widget->name }-permalink";

    $self->add_object_formatter(sub {
        my ($self, $obj, $formatted) = @_;
        $formatted->{url} = $tx->site_url_for($route, { permalink => $obj->permalink, locale => $self->widget->locale });
        $formatted->{url} = $formatted->{url}->to_abs->to_string if $formatted->{url};
    });

    $self;
}


sub with_medias {
    my ($self) = @_;
    # TODO implement $media_start $media_limit

    my $tx = $self->tx;

    $self->add_object_formatter(sub {
        my ($self, $obj, $formatted) = @_;

        my $result = $tx->api('Media')->add_list_filter('mediacollection_medias.mediacollection_id' => $obj->mediacollection_id)
                                      ->order_by('mediacollection_medias.position')
                                      ->list
                                      ->result;

        $formatted->{medias} = $result->{items};
        $formatted->{cover} = $result->{items}[0];
    });

    $self;
}


sub with_next {
    my $self = shift;


    $self->add_object_formatter(sub {
        my ($self, $obj, $formatted) = @_;

        my $result = $self->clone->reset->where('position' => { '>' => $obj->position })
                                      ->order_by('me.position')
                                      ->limit(1)
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

        my $result = $self->clone->reset->where('position' => { '<' => $obj->position })
                                      ->order_by({ -desc => 'me.position' })
                                      ->limit(1)
                                      ->list
                                      ->result;

        $formatted->{_previous} = $result->{items}->[0];
    });

    $self;
}


sub reposition {
    my ($self, @args) = @_;

    $self->resultset->result_source->schema->txn_do(sub {
        $self->_reposition(@args)
    });
}

sub _reposition {
    my ($self, $src_object, $dst_object) = @_;

    my $clone_api = $self->clone->reset;

    $src_object = $clone_api->find($src_object)->first unless ref $src_object;
    $dst_object = $clone_api->find($dst_object)->first unless ref $dst_object;

    unless ($src_object && $dst_object) {
        $self->push_error("Can't reposition: missing or invalid arguments!");
        return $self;
    }

    my $src_position = $src_object->position;
    my $dst_position = $dst_object->position;
    my $rs = $clone_api->resultset;

    if ($src_position > $dst_position) { # moving up

        $rs->search({
            'me.position' => { '>=' => $dst_position, '<' => $src_position },
            'me.widget_id' => $self->widget->id
        })->update({ position => \'position + 1' });

        $src_object->update({ position => $dst_position });

    } else {

        $rs->search({
            'me.position' => { '<=' => $dst_position, '>' => $src_position },
            'me.widget_id' => $self->widget->id
        })->update({ position => \'position - 1' });

        $src_object->update({ position => $dst_position });
    }

    $self;
}



# bump version
after [qw/ reposition /] => sub {
    my $self = shift;
    $self->widget->db_object->bump_version
        unless $self->has_errors;
};



1;
