package K1Plaza::API::MediaCollection;

use Moose;
use namespace::autoclean;
use utf8;

=head1 NAME 

K1Plaza::API::MediaCollection

=cut

extends 'DBIx::Class::API';
with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';


__PACKAGE__->config(    
    dbic_class => 'MediaCollection',
    use_json_boolean => 1,
);



1;



__PACKAGE__->meta->make_immutable();
