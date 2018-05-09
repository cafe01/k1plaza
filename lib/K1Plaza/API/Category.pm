package K1Plaza::API::Category;

use Moose;
use namespace::autoclean;

extends 'Q1::API::Tag';

with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance',
     'Q1::API::Widget::TraitFor::API::BelongsToWidget';

has '+dbic_class', default => 'Category';


1;
