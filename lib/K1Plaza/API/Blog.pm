package K1Plaza::API::Blog;

use Moose;
use namespace::autoclean;



extends 'Q1::Web::Widget::API::Blog';

with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';

__PACKAGE__->config(    
    use_json_boolean => 1,
);











__PACKAGE__->meta->make_immutable();


1;

