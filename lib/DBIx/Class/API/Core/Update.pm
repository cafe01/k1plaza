package DBIx::Class::API::Core::Update;

use namespace::autoclean;
use utf8;
use Moose::Role;
use Try::Tiny;
use List::Compare;
use Data::Dumper;


has '_allowed_update_columns'          => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );
has '_allowed_relationships_on_update' => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );
has 'reload_object_after_update'       => ( is => 'rw', isa => 'Bool', default => 0 );



sub _build__allowed_update_columns {
    my ($self) = @_;
    my $source = $self->resultset->result_source;
    my $lc = List::Compare->new('-u', '-a', [$source->columns], $self->update_forbids);
    return [$lc->get_unique];
}


sub _build__allowed_relationships_on_update {
    my ($self) = @_;
    $self->_known_relationships;
}


=head2 _build_update_forbids

This is the default implementation of the config option 'update_forbids'.

Returns a list (arrayref) of columns which are forbidden to L<update>.
Instrospects the result source and forbids the column if any of the following conditions are met:

- column is (or part of) the primary key

=cut

# TODO: create a test for forbbidn create/updates
sub _build_update_forbids {
    my ($self) = @_;

    my $source = $self->resultset->result_source;
    my $cols_info = $source->columns_info;
    my @forbidden_cols = $source->primary_columns;


    while (my ($col, $info) = each %$cols_info) {

        # TODO: create a test for 'is_read_only'
        if ( $info->{is_auto_increment} || $info->{is_read_only} || $info->{dynamic_default_on_update} ) {
            push @forbidden_cols, $col;
            next;
        }

    }

    #$self->log->debug("API: ". ref $self);
    #$self->log->debug("Forbidden columns: @forbidden_cols");

    return \@forbidden_cols;
}



=head2 update

=cut

sub update {
    my ($self, $objects) = @_;

    # prepare
    $self->_prepare_update($objects);

    # has errors ?
    return $self if $self->has_errors;

    # do
    $self->_update_or_create;

    $self;
}

sub _prepare_update {
    my ($self, $items) = @_;
    $items = [$items] unless ref $items eq 'ARRAY';

    # lookup objects
    $self->_clear_objects;

    # TODO: wrap _prepare_update_object in a try/catch, so they can die
    $self->add_object($self->_prepare_update_object($_))
        foreach @$items;

    $self;
}


sub _prepare_update_object {
    my ($self, $item) = @_;

    my @primary_key  = grep { defined } delete @$item{$self->resultset->result_source->primary_columns};
    my %updated_cols;
    my $rels = {};
    map { $updated_cols{$_} = delete $item->{$_} if exists $item->{$_} } @{ $self->_allowed_update_columns };
    map { $rels->{$_} = delete $item->{$_} if exists $item->{$_} }       @{$self->_allowed_relationships_on_create};

    #$self->log->debug("_prepare_update_object() allowed columns ". Dumper($self->_allowed_update_columns));
    # TODO: implement 'update_requires' option? is that needed? (use case: "if your are goin to update, u gotta update at least those columns")

    # if there is any column left in $item, warn as "unknown column"
    if (keys %$item) {
        $self->log->warn(sprintf("Unknown or Forbidden columns passed to update. (keys: %s)", join ', ', keys %$item));
    }

    # invalid keys
    die "update error: can't lookup object: no keys"
        unless @primary_key;

    # lookup object
    my $object = $self->_lookup_object(@primary_key);

    # lookup failed. abort operation
    unless ($object) {
        $self->push_error("Can't update. Failed to lookup object. (pk: @primary_key)");
        $self->_clear_objects;
        return $self;
    }

    # set columns
    $object->set_inflated_columns(\%updated_cols);

    # return item
    return {
        object    => $object,
        related   => $rels
    };
}


=head2 _update_object_relationships

=cut

sub _update_object_relationships {
    my ($self, $object, $related) = @_;

    # insert related
    foreach my $rel (keys %$related) {

        # prepare related
        if (my $method = $self->can("_prepare_related_$rel")) {
            $related->{$rel} = $self->$method($related->{$rel});
        }

        next unless ref $related->{$rel};

        # m2m
        if (my $method = $object->can("set_$rel")) {
            $object->$method($related->{$rel});
            next;
        }

        # has_many
        if (my $method = $object->can("add_to_$rel")) {
            $related->{$rel} = [$related->{$rel}] unless ref $related->{$rel} eq 'ARRAY';
            $object->$method($_) foreach @{$related->{$rel}};
            next;
        }
    }
}


=head2 _update_object

=cut

sub _update_object {
    my ($self, $item) = @_;
    my $object  = $item->{object};
    my $related = $item->{related};

    $object->update;
    $object->discard_changes if $self->reload_object_after_update;

    # related
    $self->_update_object_relationships($object, $related);
}














1;
