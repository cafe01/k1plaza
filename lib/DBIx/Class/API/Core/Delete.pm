package DBIx::Class::API::Core::Delete;

use namespace::autoclean;
use utf8;
use Moose::Role;
use Try::Tiny;
use List::Compare;
use Data::Dumper;


=head2 delete

=cut

sub delete {
    my ($self, $objects) = @_;

    # prepare
    $self->_prepare_delete($objects);

    # has errors ?
    return $self if $self->has_errors;

    # do
    $self->_delete_objects;

    $self;
}


=head2 _prepare_delete

=cut

sub _prepare_delete {
    my ($self, $items) = @_;
    $items = [$items] unless ref $items eq 'ARRAY';

    # lookup objects
    $self->_clear_objects;

    my @pk_cols = $self->resultset->result_source->primary_columns;

    for (my $i = 0; $i < @$items; $i++) {

        # lookup object
        my $item = $items->[$i];
        my @primary_key = ref $item ? delete @$item{@pk_cols} : ($item);
        my $object = $self->_lookup_object(@primary_key);

        # lookup failed. abort operation
        unless ($object) {
            $self->log->error();
            $self->push_error("Can't delete. Failed to lookup object. (item: $i, pk: @primary_key)");
            $self->_clear_objects;
            return $self;
        }

        # stage object
        $self->add_object($object);
    }

    $self;
}



=head2 _delete_objects

=cut

sub _delete_objects {
    my ($self, $objects) = @_;

    if ($self->has_objects)
    {
        $self->_delete_object($_) foreach ($self->all_objects);
    }
    else
    {
        $self->push_error("Can't delete. No objects on which to operate");
    }
}



=head2 _delete_object

=cut

sub _delete_object {
    my ($self, $object) = @_;
    $object->delete;
}




1;
