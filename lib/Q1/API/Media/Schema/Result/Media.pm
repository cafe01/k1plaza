package Q1::API::Media::Schema::Result::Media;

use strict;
use DBIx::Class::Candy
  -autotable  => v1,
  -components => [qw/ IntrospectableM2M InflateColumn::FS UUIDColumns InflateColumn::Serializer TimeStamp Core /];



primary_column 'id' => {
	data_type         => 'int',
	is_auto_increment => 1,
};

unique_column uuid => {
	data_type => 'char',
	size      => 32,
};

column is_audio => {
    data_type     => 'boolean',
    default_value => 0,
};

column is_video => {
    data_type     => 'boolean',
    default_value => 0,
};

column is_image => {
    data_type     => 'boolean',
    default_value => 0,
};

column has_file => {
    data_type     => 'boolean',
    default_value => 0,
};

column is_external => {
    data_type     => 'boolean',
    default_value => 0,
};

column external_id => {
    data_type   => 'varchar',
    size        => 196,
    is_nullable => 1,
};

column external_provider => {
    data_type   => 'varchar',
    size        => 196,
    is_nullable => 1,
};

column thumbnail_small => {
    data_type   => 'varchar',
    size        => 512,
    is_nullable => 1,
};

column thumbnail_large => {
    data_type   => 'varchar',
    size        => 512,
    is_nullable => 1,
};

column waveform_url => {
    data_type   => 'varchar',
    size        => 512,
    is_nullable => 1,
};

column file => {
    data_type      => 'varchar',
    size           => 512,
    is_nullable    => 1,
    is_fs_column   => 1,
    fs_column_path => 'file_storage/medias',
};

column s3file => {
    data_type      => 'varchar',
    size           => 255,
    is_nullable    => 1,
};

column file_size => {
	data_type     => 'integer',
	is_nullable   => 1,
	extra         => { unsigned => 1 }
};

column file_name => {
	data_type   => 'varchar',
	size        => 255,
	is_nullable => 1,
};

column file_mime_type => {
	data_type   => 'varchar',
	size        => 128,
	is_nullable => 1,
};

column width => {
	data_type     => 'integer',
	is_nullable   => 1,
	extra         => { unsigned => 1 }
};

column height => {
    data_type     => 'integer',
    is_nullable   => 1,
    extra         => { unsigned => 1 }
};

column duration => {
    data_type     => 'integer',
    is_nullable   => 1,
    extra         => { unsigned => 1 }
};

column metadata => {
    data_type           => 'text',
    serializer_class    => 'JSON',
};

column created_at => {
	data_type     => 'datetime',
	set_on_create => 1,
	set_on_update => 0,
};

column updated_at => {
	data_type     => 'datetime',
	set_on_create => 1,
	set_on_update => 1,
};


__PACKAGE__->uuid_columns('uuid');



sub get_uuid {
    my ($self) = @_;
    my $uuid = $self->next::method;
    $uuid =~ tr/-//d;
    return lc $uuid;
}

sub insert {
    my $self = shift;

    $self->metadata({}) unless $self->has_column_loaded('metadata');
    $self->next::method(@_);
}


1;

__END__

=pod

=head1 NAME

Q1::API::Media::Schema::Result::Media

=head1 DESCRIPTION

Media result class.

=head1 COLUMNS

id
uuid
is_audio
is_video
is_image
has_file
is_external
external_id
external_provider
thumbnail_small
thumbnail_large
file
file_size
file_name
file_mime_type
width
height
duration
metadata
created_at
updated_at

=head1 METHODS

=head2 get_uuid

Removes the dashed from the default uuid generator.

=head2 insert

Sets the default value for 'metadata' (which is {}).

=cut
