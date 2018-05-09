package K1Plaza::Schema::Result::Tag;


=head1 NAME CommentStuff::Schema::Result::Tag


=cut

use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -base => 'DBIx::Class::API::Feature::Tags::Schema::Result::Tag',
    -components => [qw/ Helper::Row::SubClass IntrospectableM2M Core /];



column widget_id => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};

belongs_to 'widget' => 'K1Plaza::Schema::Result::Widget', 'widget_id', {  };


subclass;

unique_constraint unique_tag_slug => [qw/ widget_id slug /];


1;
