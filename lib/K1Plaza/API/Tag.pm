package K1Plaza::API::Tag;

use Moose;
use namespace::autoclean;
use utf8;


extends 'Q1::API::Tag';

with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance',
     'Q1::API::Widget::TraitFor::API::BelongsToWidget';



has '+use_json_boolean' => ( default => 1 );


__PACKAGE__->meta->make_immutable();




1;
