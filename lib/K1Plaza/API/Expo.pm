package K1Plaza::API::Expo;

use Moose;
use namespace::autoclean;

extends 'Q1::Web::Widget::API::Expo';

with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';

__PACKAGE__->config(    
    use_json_boolean => 1,
    expo_group_column => 'widget_id'
);



1;

