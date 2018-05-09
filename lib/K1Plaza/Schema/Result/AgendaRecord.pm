package K1Plaza::Schema::Result::AgendaRecord;


use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::Web::Widget::Schema::Result::AgendaRecord',
    -components => [qw/ +DBIx::Class::Helper::Many2Many Helper::Row::SubClass /];

subclass;


belongs_to 'widget' => 'K1Plaza::Schema::Result::Widget', 'widget_id';


1;

