package K1Plaza::Schema::Result::PaymentNotification;


use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::Web::API::Payment::Schema::PaymentNotification',
    -components => ['Helper::Row::SubClass'];

subclass;

belongs_to 'status', 'K1Plaza::Schema::Result::PaymentStatus', 'status_id';
belongs_to 'payment', 'K1Plaza::Schema::Result::Payment', 'payment_id';




1;
