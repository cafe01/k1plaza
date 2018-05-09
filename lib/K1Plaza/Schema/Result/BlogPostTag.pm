package K1Plaza::Schema::Result::BlogPostTag;


=head1 NAME 

K1Plaza::Schema::Result::BlogPostTag

=cut

use strict;
use DBIx::Class::Candy -autotable => v1;


column 'blogpost_id'   => { data_type => 'int' };
column 'tag_id'   => { data_type => 'int' };

primary_key 'blogpost_id', 'tag_id';




1;

