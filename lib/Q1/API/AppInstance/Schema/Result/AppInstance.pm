package Q1::API::AppInstance::Schema::Result::AppInstance;


use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ IntrospectableM2M TimeStamp UUIDColumns Core /];

use Moose;
use Class::Load;
use namespace::autoclean;


primary_column 'id' => {
	data_type          => 'int',
	is_auto_increment  => 1,
};

column 'name' => {
    data_type       => 'varchar',
    size            => 255
};

unique_column 'uuid' => {
    data_type => 'char',
    size      => 32,
};

unique_column 'canonical_alias' => {
    data_type       => 'varchar',
    size            => 255,
};

column 'repository_url' => {
    data_type       => 'varchar',
    size            => 255,
    is_nullable => 1
};

column 'base_dir' => {
    data_type       => 'varchar',
    size            => 255,
    is_nullable => 1
};

column 'is_managed' => {
    data_type       => 'boolean',
    default_value   => 0
};

column 'deployment_version' => {
    data_type => 'char',
    size => 40,
    is_nullable => 1
};

column 'created_at' => {
    data_type       => 'datetime',
    set_on_create   => 1,
    timezone        => "UTC",
    is_read_only    => 1
};

column 'hosting_expires_at' => {
    data_type       => 'date',
    set_on_create   => 1,
    timezone        => "UTC",
    is_nullable => 1
};


has_many 'aliases', 'Q1::API::AppInstance::Schema::Result::AppInstance::Alias', 'app_instance_id';



__PACKAGE__->uuid_columns('uuid');




sub instance_has_many {
	my ($class, $relname, $relclass, $fk_column, $fk_relname) = @_;
	$fk_column  ||= 'app_instance_id';
	$fk_relname ||= 'app_instance';

	Class::Load::load_class($relclass);

    $relclass->add_column( $fk_column => {
        data_type => 'int',
    });

	$class->has_many( $relname, $relclass, $fk_column );

	$relclass->belongs_to($fk_relname, $class, $fk_column);

}


sub get_uuid {
    my ($self) = @_;
    my $uuid = $self->next::method;
    $uuid =~ tr/-//d;
    return lc $uuid;
}

sub raw {
    +{ shift->get_columns }
}


sub as_hashref {
    my $self = shift;
    +{ $self->get_columns }
}



1;



__END__

=pod

=head1 NAME

Q1::API::AppInstance::Schema::Result::AppInstance

=head1 SYNOPSIS

    package MyApp::Schema::Result::AppInstance;


    use DBIx::Class::Candy
        -autotable => v1,
        -base => 'Q1::API::AppInstance::Schema::Result::AppInstance',
        -components => ['Helper::Row::SubClass'];


    # subclass
    subclass;


    # has many stuffs
    __PACKAGE__->instance_has_many('stuffs', 'MyApp::Schema::Result::Stuff');


    ...

=head1 DESCRIPTION

Base class for MyApp::Schema::Result::AppInstance.

=cut

=head1 METHODS

=head2 instance_has_many

Arguments: $relname, $relclass [, $fk_column [, $fk_relname]]

Creates a has_many relationship named $relname from this class to $relclass.
Also configures the related class by adding the $fk_column ('app_instance_id' by default) column,
and the belongs_to relationship named $fk_relname ('app_instance' by default).


=head2 increment_latest_version

=cut
