package K1Plaza::API::Links;

use Moose;
use namespace::autoclean;



extends 'Q1::Web::Widget::API::Links';

with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance',     
     'Q1::API::Widget::TraitFor::API::BelongsToWidget';

__PACKAGE__->config(    
    use_json_boolean => 1,
);



1;

