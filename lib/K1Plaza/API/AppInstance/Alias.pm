package K1Plaza::API::AppInstance::Alias;

use Moose;
use namespace::autoclean;
use utf8;

extends 'DBIx::Class::API';


with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';


__PACKAGE__->config(    
    dbic_class => 'AppInstance::Alias',
    use_json_boolean => 1,
);




1;



__PACKAGE__->meta->make_immutable();
