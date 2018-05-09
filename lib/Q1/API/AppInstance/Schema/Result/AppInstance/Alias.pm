package Q1::API::AppInstance::Schema::Result::AppInstance::Alias;


use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ TimeStamp Core /];

use strict;
                       
=head1 NAME Q1::API::AppInstance::Schema::Result::AppInstance


=cut


primary_column 'id' => {
	data_type          => 'int',
	is_auto_increment  => 1,
};

column 'app_instance_id' => {
    data_type          => 'int',
};


unique_column 'name' => {
    data_type       => 'varchar',    
    size            => 255,
};

column 'environment' => {
    data_type       => 'enum',    
    extra           => { list => [qw/ development testing production /]},
    default_value   => 'production'
};


belongs_to 'app_instance', 'Q1::API::AppInstance::Schema::Result::AppInstance', 'app_instance_id';



1;