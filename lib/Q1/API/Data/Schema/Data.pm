package Q1::API::Data::Schema::Data;

use strict;
use DBIx::Class::Candy -components => [qw/ Core /];


table 'app_instance_data';

primary_column 'name' => {
    data_type  => 'char',
    size => 128
};

column 'value' => {
    data_type => 'text'
};

column 'is_serialized' => {
    data_type => 'boolean',
    default_value => 0
};


1;


__END__
