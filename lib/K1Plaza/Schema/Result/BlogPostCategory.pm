package K1Plaza::Schema::Result::BlogPostCategory;


=head1 NAME 

K1Plaza::Schema::Result::BlogPostCategory

=cut

use strict;
use DBIx::Class::Candy -autotable => v1;


column 'blogpost_id'   => { data_type => 'int' };
column 'category_id'   => { data_type => 'int' };

primary_key 'blogpost_id', 'category_id';




1;

