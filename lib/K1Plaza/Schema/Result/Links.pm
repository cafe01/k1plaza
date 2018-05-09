package K1Plaza::Schema::Result::Links;


use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::Web::Widget::Schema::Result::Links',
    -components => ['Helper::Row::SubClass'];

subclass;


belongs_to 'widget' => 'K1Plaza::Schema::Result::Widget', 'widget_id';

1;

