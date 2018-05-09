package Q1::Web::Widget::Schema::Result::GuestBook;

use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -components => [qw/ IntrospectableM2M TimeStamp Core /];



primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};


column widget_id => {
    data_type       => 'integer',
    is_foreign_key  => 1,
}; 


column 'author_id' => {
    data_type      => 'int',
    is_foreign_key => 1,
    is_nullable    => 1,
};


column 'name' => {
    data_type     => 'varchar',
    size          => 255,
};


column 'email' => {
    data_type     => 'varchar',
    size          => 255,
};


column 'message' => {
    data_type     => 'varchar',
    size          => 1024,
};


column 'created_at' => {
    data_type     => 'datetime',
    set_on_create => 1,
    timezone      => "UTC",
};


column updated_at => {
    data_type     => 'datetime',
    set_on_create => 1,
    set_on_update => 1,
    timezone      => "UTC",
};





1;


__END__

=head1 NAME 

Q1::Web::Widget::Schema::Result::GuestBook

=cut