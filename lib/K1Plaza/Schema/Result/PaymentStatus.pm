package K1Plaza::Schema::Result::PaymentStatus;


use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::Web::API::Payment::Schema::PaymentStatus',
    -components => ['Helper::Row::SubClass'];

subclass;

1;
