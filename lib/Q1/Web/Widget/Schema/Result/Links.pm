package Q1::Web::Widget::Schema::Result::Links;

use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -components => [qw/ Core /];



primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};


column widget_id => {
    data_type       => 'integer',
    is_foreign_key  => 1,
}; 


column 'title' => {
    data_type     => 'varchar',
    size          => 255,
};

column 'url' => {
    data_type     => 'varchar',
    size          => 512,
};


column 'clicks' => {
    data_type     => 'int',
    default_value => 0
};



sub increment_clicks {
	my ($self) = @_;
	$self->update( clicks => \ 'clicks + 1');
}



1;


__END__

=head1 NAME 

Q1::Web::Widget::Schema::Result::Links

=cut