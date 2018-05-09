package K1Plaza::Schema::Result::AppInstance::ACL;


use DBIx::Class::Candy -autotable => v1,
                       -base => 'Q1::API::AppInstance::Schema::Result::AppInstance::ACL',
                       -components => [qw/ Helper::Row::SubClass /];
                       
subclass;

belongs_to 'app_instance', 'K1Plaza::Schema::Result::AppInstance', 'app_instance_id';
belongs_to 'user' => 'K1Plaza::Schema::Result::User', 'user_id';


1;