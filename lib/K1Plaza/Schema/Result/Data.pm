package K1Plaza::Schema::Result::Data;


use strict;
use DBIx::Class::Candy
    -base => 'Q1::API::Data::Schema::Data',
    -components => ['Helper::Row::SubClass'];


subclass;

column app_instance_id => {
    data_type       => 'int',
    is_foreign_key  => 1,
};

primary_key qw/ app_instance_id name /;

1;
