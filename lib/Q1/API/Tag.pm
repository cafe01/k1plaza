package Q1::API::Tag;

use Moose;
use namespace::autoclean;


extends 'DBIx::Class::API';

with 'DBIx::Class::API::Feature::Permalink';


has '+dbic_class'       => ( default => 'Tag' );
has '+use_json_boolean' => ( default => 1 );
has '+sortable_columns' => ( default => sub { [qw/ me.name /] } );

has '+permalink_column' => ( default => 'slug' );
has '+permalink_source_column' => ( default => 'name' );
has '+unique_permalink_constraint' => ( default => 'unique_tag_slug' );
has '+generate_permalink_on_update' => ( default => 0 );


around 'find_or_create' => sub {
    my $orig = shift;
    my $self = shift;
    my ($items) = @_;
    $items = [$items] unless ref $items eq 'ARRAY';

    my @prepared_items;
    foreach (@$items) {
        push @prepared_items, ref $_ eq 'HASH' ? $_ : { name => $_ };
    }

    $self->$orig(\@prepared_items);
};


# auto trim name
around '_prepare_create_object' => sub {
    my ($orig, $self, $data) = @_;
    $data->{name} =~ s/^\s+|\s+$//g;
    $self->$orig($data);
};

around '_update_object' => sub {
    my $orig = shift;
    my $self = shift;
    my ($item) = @_;
    my $object  = $item->{object};

    if ($object->is_column_changed('name')) {
        my $name = $object->name;
        $name =~ s/^\s+|\s+$//g;
        $object->name($name);
    }

    $self->$orig(@_);
};

sub generate_tag_cloud {
    my ($self, $params) = @_;
    $params ||= {};
    my $rs = $self->resultset;

    #my $relationship_info = $rs->result_source->reverse_relationship_info($params{relationship});

    # defaults
    $params = {
       item_count_column   => 'item_count',
       max_font_size       => 30,
       min_font_size       => 10,
       skip_empty          => 1,
       %$params
    };

    # error
    confess "generate_tag_cloud() requires the 'relationship' parameter"
       unless $params->{relationship};

    # set query
    $self->order_by({ -asc => 'me.name' });
    $self->set_search_attribute( 'join'     => $params->{relationship});
    $self->set_search_attribute( 'group_by' => 'me.id');
    $self->set_search_attribute( '+columns' => [{ $params->{item_count_column} => { count => join('.', %{$params->{relationship}}).'_id', -as => $params->{item_count_column} }}] );

    $self->set_search_attribute( 'having' => { $params->{item_count_column} => { '>' => 0 }})
        if $params->{skip_empty};

    $self->modify_resultset($params->{cond})
        if $params->{cond};

    # do it
    my $result = $self->list->result;

    ## format result

    # find min/max count
    my ($min_count, $max_count);
    foreach my $item (@{ $result->{items} }) {

        my $item_count = $item->{$params->{item_count_column}};

        $min_count = $item_count unless defined $min_count;
        $max_count = $item_count unless defined $max_count;

        $min_count = $item_count if $item_count < $min_count;
        $max_count = $item_count if $item_count > $max_count;
    }

    # calculate font size
    foreach my $item (@{ $result->{items} }) {

        my $item_count = $item->{$params->{item_count_column}};

        my $delta = $max_count > $min_count ? $max_count - $min_count : 1;
        my $relative_max_font_size = $params->{max_font_size} - $params->{min_font_size};

        $item->{font_size} = $item_count > $min_count ? $params->{min_font_size} + ($relative_max_font_size * ($item_count - $min_count) / $delta)
                                                      : $params->{min_font_size};
    }

    # return
    $result;
}

sub _string_to_hash {
    return { name => $_[1] };
}




__PACKAGE__->meta->make_immutable();




1;
