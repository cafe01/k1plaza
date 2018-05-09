package K1Plaza::Schema::Result::ExpoTag;


=head1 NAME 

K1Plaza::Schema::Result::ExpoTag

=cut

use strict;
use DBIx::Class::Candy -autotable => v1;


column 'expo_id'   => { data_type => 'int' };
column 'tag_id'   => { data_type => 'int' };

primary_key 'expo_id', 'tag_id';




1;

