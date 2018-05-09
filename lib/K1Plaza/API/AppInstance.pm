package K1Plaza::API::AppInstance;

use Moose;
use namespace::autoclean;


extends 'Q1::API::AppInstance';


__PACKAGE__->config(
    dbic_class => 'AppInstance',
    use_json_boolean => 1,
    sortable_columns => [qw/ me.created_at /]
);

1;
