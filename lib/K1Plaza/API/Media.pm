package K1Plaza::API::Media;

use Moose;
use namespace::autoclean;


extends 'Q1::API::Media';

with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';


__PACKAGE__->config(
    use_json_boolean => 1,
);













1;
