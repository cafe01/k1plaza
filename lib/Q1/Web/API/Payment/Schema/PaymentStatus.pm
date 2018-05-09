package Q1::Web::API::Payment::Schema::PaymentStatus;

use strict;
use DBIx::Class::Candy
    -components => [qw/ Core /];

table 'payment_status';

primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};

unique_column 'name' => {
    data_type     => 'char',
    size          => 32,
};


1;
