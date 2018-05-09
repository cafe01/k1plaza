package DBIx::Class::API::Core::Create;

use namespace::autoclean;
use utf8;
use Moose::Role;
use Try::Tiny;
use List::Compare;
use Data::Dumper;


has '_allowed_create_columns'           => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );
has '_allowed_relationships_on_create'  => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );


sub _build__allowed_create_columns {
    my ($self) = @_;
    my $source = $self->resultset->result_source;
    my $lc = List::Compare->new('-u', '-a', [$source->columns], $self->create_forbids);
    return [$lc->get_unique];
}

sub _build__allowed_relationships_on_create {
    my ($self) = @_;
    $self->_known_relationships;
}





=head2 _build_create_forbids

This is the default implementation of the config option 'create_forbids'.

Returns a list (arrayref) of columns which are forbidden to L<create>.
Instrospects the result source and forbids the column if any of the following conditions are met:

- column is_auto_increment

=cut

sub _build_create_forbids {
    my ($self) = @_;

    my $cols_info = $self->resultset->result_source->columns_info;
    my @forbidden_cols;

    while (my ($col, $info) = each %$cols_info) {

        #$self->log->debug("[API::create] col info:", Dumper($info)) if $col =~ '\w+_at$';
        if ( $info->{is_auto_increment} || $info->{dynamic_default_on_create} ) {
            push @forbidden_cols, $col;
            next;
        }

    }

    #$self->log->debug("[API::create] forbidden cols: @forbidden_cols");
    return \@forbidden_cols;
}




=head2 create

=cut

sub create {
    my ($self, $objects) = @_;

    # prepare
    $self->_prepare_create($objects);

    # has errors ?
    return $self if $self->has_errors;

    # do
    $self->_update_or_create;

    $self;
}

sub _prepare_create {
    my ($self, $items) = @_;
    $items = [$items] unless ref $items eq 'ARRAY';

    # prepare objects
    $self->_clear_objects;

    # TODO: wrap _prepare_create_object in a try/catch, so they can die
    $self->add_object($self->_prepare_create_object($_))
        foreach @$items;

    $self;
}

sub _prepare_create_object {
    my ($self, $item) = @_;

    my $cols = {};
    my $rels = {};

    map { $cols->{$_} = delete $item->{$_} if exists $item->{$_} } @{$self->_allowed_create_columns};
    map { $rels->{$_} = delete $item->{$_} if exists $item->{$_} } @{$self->_allowed_relationships_on_create};

    # TODO: implement 'create_requires' option (use case: "if your are goin to create, u gotta supply at least those columns") can be reflected from result class

    # if there is any column left in $item, warn as "unknown column"
    if (keys %$item) {
        $self->log->debug(sprintf("Unknown or Forbidden columns passed to create. (keys: %s)", join ', ', keys %$item));
    }

    # prepare related
    my $rs = $self->resultset->result_source;
    foreach my $rel (keys %$rels) {
        next unless $rs->has_relationship($rel);
        if (my $method = $self->can("_prepare_related_$rel")) {
            $cols->{$rel} = $self->$method( delete $rels->{$rel});
        }
    }

    return {
        object    => $self->resultset->new_result($cols),
        related   => $rels
    };
}


=head2 create_or_update

=cut

sub create_or_update {
    my ($self, $objects, @keys) = @_;

    # prepare
    $self->_prepare_create_or_update($objects, @keys);

    # has errors ?
    return $self if $self->has_errors;

    # do
    $self->_update_or_create;

    $self;
}

sub _prepare_create_or_update {
    my ($self, $items, @keys) = @_;
    $items = [$items] unless ref $items eq 'ARRAY';
    my $rs = $self->resultset;
    @keys = $rs->result_source->primary_columns
        unless @keys;

    my $clone_api = $self->clone->reset;


    for (my $i = 0; $i < @$items; $i++) {
        my $item = $items->[$i];

        my %where;
        foreach my $key (@keys) {
            $item->{$key} ? ($where{$key} = $item->{$key}) : undef %where;
        }

        my $object = $clone_api->find(\%where, { 'for' => 'update' })->first
            if %where;

        if ($object) { # update
            $object->set_inflated_columns($item);
            $self->add_object({ object => $object });
            #$self->add_object($self->_prepare_update_object($item));
        }
        else { # create
            $self->add_object($self->_prepare_create_object($item));
        }
    }

    $self;
}




=head2 _lookup_object

=cut

sub _lookup_object {
    my ($self, @args) = @_;
    $self->clone->reset->find(@args)->first;
}


=head2 _update_or_create

=cut

sub _update_or_create
{
    my ($self) = @_;

    if ($self->has_objects)
    {
        #$self->_validate_objects;
        $self->_transact_objects( sub { $self->_save_objects(@_) } );

        # return objects?
        $self->_clear_objects
           unless $self->return_objects;
    }
    else
    {
        $self->push_error('No objects on which to operate');
    }
}



=head2 _transact_objects

=cut

sub _transact_objects {
    my ($self, $coderef) = @_;

    try
    {
        $self->resultset->result_source->schema->txn_do
        (
            $coderef,
            [$self->all_objects]
        );
    }
    catch
    {
        $self->log->error( sprintf("Error while transacting objects: $_") );
        $self->push_error('a database error has occured');
    }

}



=head2 _save_objects

=cut

sub _save_objects {
    my ($self, $objects) = @_;

    foreach my $obj (@$objects) {
        if ($obj->{object}->in_storage)
        {
            $self->_update_object($obj);
        }
        else
        {
            $self->_insert_object($obj);
        }
    }
}







=head2 _insert_object

=cut

sub _insert_object {
    my ($self, $item) = @_;

    my $object  = $item->{object};
    my $related = $item->{related};

    # insert objects
    $object->insert;
    $object->discard_changes if $self->flush_object_after_insert;

    # related
    $self->_update_object_relationships($object, $related);
}






=head2 find_or_create

=cut

sub find_or_create {
    my ($self, $items) = @_;
    $items = [$items] unless ref $items eq 'ARRAY';

    my @objects;
    my $clone_api = $self->clone->reset;

    foreach my $item (@$items) {
        $item = $self->_string_to_hash($item) unless ref $item;
        push @objects, $clone_api->find({ %$item })->first || $clone_api->create({ %$item })->first->{object};
    }

    \@objects;
}





1;
