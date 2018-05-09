package K1Plaza::Schema::Result::Expo;


use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::Web::Widget::Schema::Result::Expo',
    -components => [qw/ +DBIx::Class::Helper::Many2Many Helper::Row::SubClass /];

subclass;


belongs_to 'widget' => 'K1Plaza::Schema::Result::Widget', 'widget_id', {  };


__PACKAGE__->many2many('K1Plaza::Schema::Result::Tag');

1;

