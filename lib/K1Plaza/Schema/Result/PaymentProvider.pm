package K1Plaza::Schema::Result::PaymentProvider;


use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::Web::API::Payment::Schema::PaymentProvider',
    -components => ['Helper::Row::SubClass'];

subclass;

1;
