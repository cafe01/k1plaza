package K1Plaza::API::Role;

use Moose;
use namespace::autoclean;
use utf8;

extends 'DBIx::Class::API';


with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';


__PACKAGE__->config(    
    dbic_class => 'Role',
    use_json_boolean => 1,
);

sub find_by_name {
    my ($self, $name) = @_;
    $self->find({ 'me.rolename' => $name })->first;
}

sub _string_to_hash {
    +{ rolename => $_[1] };    
}


1;



__PACKAGE__->meta->make_immutable();
