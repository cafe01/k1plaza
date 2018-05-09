package Q1::Web::API::Payment::Schema::PaymentNotification;

use strict;
use DBIx::Class::Candy
    -components => [qw/ TimeStamp Core /];

table 'payment_notifications';

primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};

column 'payment_id' => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};

column 'status_id' => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};

column 'raw' => {
    data_type => 'text'
};

column 'date' => {
    data_type     => 'datetime',
    set_on_create => 0,
    set_on_update => 0,
    timezone      => "UTC",
};

column 'created_at' => {
    data_type     => 'datetime',
    set_on_create => 1,
    set_on_update => 0,
    timezone      => "UTC",
};


1;
