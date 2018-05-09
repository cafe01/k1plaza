package K1Plaza::Schema::Result::Widget;

use DBIx::Class::Candy -autotable => v1,
                       -base => 'Q1::API::Widget::Schema::Result::Widget',
                       -components => [qw/ Helper::Row::SubClass Core  /];

subclass;

column 'app_instance_id' => {
    data_type => 'int'
};

unique_constraint [qw/ app_instance_id name /];

has_many 'expos'      => 'K1Plaza::Schema::Result::Expo', 'widget_id';
has_many 'blog_posts' => 'K1Plaza::Schema::Result::BlogPost', 'widget_id';



1;
