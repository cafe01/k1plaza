package K1Plaza::Schema::Result::AppInstance::Alias;


use DBIx::Class::Candy -autotable => v1,
                       -base => 'Q1::API::AppInstance::Schema::Result::AppInstance::Alias',
                       -components => [qw/ Helper::Row::SubClass /];

use strict;
             
                       
=head1 NAME 

K1Plaza::Schema::Result::AppInstance::Alias

=cut

subclass;



1;