package Q1::API::AppInstance::Schema::Result::AppInstance::ACL;


use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ TimeStamp Core /];

use strict;


primary_column 'app_instance_id' => {
    data_type          => 'int',
};


primary_column 'user_id' => {
    data_type          => 'int',
};






1;
