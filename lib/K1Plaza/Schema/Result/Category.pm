package K1Plaza::Schema::Result::Category;

=head1 NAME K1Plaza::Schema::Result::Category


=cut

use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -components => [qw/ IntrospectableM2M TimeStamp Core /];



primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};

column 'name' => {
    data_type => 'varchar',
    size      => 255,
};


column 'slug' => {
    data_type => 'varchar',
    size      => 255,
};


column app_instance_id => {
    data_type       => 'int',
    is_foreign_key  => 1,
};

column widget_id => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};

belongs_to 'widget' => 'K1Plaza::Schema::Result::Widget', 'widget_id', {  };

unique_constraint unique_tag_slug => [qw/ widget_id slug /];





1;
