package DBIx::Class::API::Feature::Tags::Schema::Result::Tag;

use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ Core /];



primary_column 'id' => {
   data_type => 'int',
   is_auto_increment => 1,
};

column 'name' => {
    data_type => 'varchar',
    size      => 256,
};


column 'slug' => {
    data_type => 'varchar',
    size      => 255,
    is_nullable => 0
};

1;
