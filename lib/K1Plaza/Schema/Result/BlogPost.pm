package K1Plaza::Schema::Result::BlogPost;


use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::Web::Widget::Schema::Result::BlogPost',
    -components => [qw/ +DBIx::Class::Helper::Many2Many Helper::Row::SubClass /];

subclass;


belongs_to 'widget' => 'K1Plaza::Schema::Result::Widget', 'widget_id';

belongs_to 'author' => 'K1Plaza::Schema::Result::User', 'author_id', { join_type => 'left' };


__PACKAGE__->many2many('K1Plaza::Schema::Result::Category');
__PACKAGE__->many2many('K1Plaza::Schema::Result::Tag');




1;
