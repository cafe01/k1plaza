package K1Plaza::Schema::Result::Payment;


use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::Web::API::Payment::Schema::Payment',
    -components => ['Helper::Row::SubClass'];

subclass;


belongs_to 'status', 'K1Plaza::Schema::Result::PaymentStatus', 'status_id';
belongs_to 'provider', 'K1Plaza::Schema::Result::PaymentProvider', 'provider_id';
has_many 'notifications', 'K1Plaza::Schema::Result::PaymentNotification', 'payment_id';

1;
