package Q1::Web::API::Payment::Schema::PaymentProvider;

use strict;
use DBIx::Class::Candy
    -components => [qw/ Core /];

table 'payment_providers';

primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};

unique_column 'name' => {
    data_type     => 'char',
    size          => 64,
};


1;
