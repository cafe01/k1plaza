package Q1::API::Media::Schema::Result::MediaCollection;

use strict;
use DBIx::Class::Candy
  -autotable  => v1,
  -components => [qw/ +DBIx::Class::Helper::Many2Many Helper::Row::SubClass TimeStamp Core/];

=head1 NAME 

Q1::API::Media::Schema::Result::MediaCollection

=head1 COLUMNS

id

=cut

primary_column 'id' => {
	data_type         => 'int',
	is_auto_increment => 1,
};


#__PACKAGE__->many2many('Q1::API::Media::Schema::Result::Media');

1;

