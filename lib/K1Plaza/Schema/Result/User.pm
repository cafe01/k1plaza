package K1Plaza::Schema::Result::User;

=head1 NAME K1Plaza::Schema::Result::User


=cut

use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -components => [qw/ +DBIx::Class::Helper::Many2Many IntrospectableM2M TimeStamp Core /];


use Gravatar::URL ();

primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};

column 'facebook_id' => {
    data_type      => 'varchar',
    size           => 128,
    is_nullable    => 1,
};

column 'google_id' => {
    data_type      => 'char',
    size           => 25,
    is_nullable    => 1,
};

column 'first_name' => {
    data_type => 'varchar',
    size      => 255,
    default_value => '',
};

column 'last_name' => {
    data_type => 'varchar',
    size      => 255,
    default_value => '',
};

column 'email' => {
    data_type => 'varchar',
    size      => 255,
    default_value => '',
};

column 'image_url' => {
    data_type => 'varchar',
    size      => 255,
    is_nullable => 1,
};

column 'created_at' => {
    data_type     => 'datetime',
    set_on_create => 1,
};

column 'last_login_at' => {
    data_type   => 'datetime',
    is_nullable => 1
};


column 'app_instance_id';


unique_constraint [qw/ app_instance_id facebook_id /];
unique_constraint [qw/ app_instance_id email /];


__PACKAGE__->many2many('K1Plaza::Schema::Result::Role');


sub name  {
    my $self = shift;
    join ' ', $self->first_name || '', $self->last_name || '';
}

sub fullname  {
    shift->name;
}

sub icon {
	my ($self) = @_;

    return $self->image_url if $self->image_url;

	return sprintf("https://graph.facebook.com/%s/picture?type=square", $self->facebook_id)
	   if $self->facebook_id;

    return Gravatar::URL::gravatar_url(email => $self->email);
}

sub as_hashref {
    +{ shift->get_columns }
}

sub TO_JSON {
    shift->as_hashref
}

1;
