package Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance;

use Moose::Role;
use namespace::autoclean;
use Carp qw/ croak confess /;
use Data::Printer;

has 'auto_restrict_by_app_instance' => ( is => 'rw', isa => 'Bool', default => 1 );
has 'app_instance_id', is => 'rw', isa => 'Int';


sub restrict_by_app_instance {
	my ($self, $app_instance_id) = @_;

	$app_instance_id ||= $self->app_instance_id;

	confess "Sorry but I can't restrict_by_app_instance() since I got no app instance id to restric by! Duh!"
	   unless defined $app_instance_id;

    confess "Passing an app instance OBJECT to restrict_by_app_instance() is deprecated! Pass only the ID please."
       if ref $app_instance_id;

	$self->app_instance_id($app_instance_id);
	$self->modify_resultset({ 'me.app_instance_id' => $app_instance_id });
	$self;
};


before _prepare_read => sub {
	my $self = shift;
	$self->restrict_by_app_instance if $self->auto_restrict_by_app_instance;
};




around '_prepare_create_object' => sub {
    my $orig  = shift;
    my $self  = shift;
    my $item  = shift;

    return $self->$orig($item)
        unless $self->auto_restrict_by_app_instance;

    die "[".ref($self)."] You cant create without a app_instance! I need to populate the app_instance_id column..."
        unless defined $self->app_instance_id;

    $item->{app_instance_id} = $self->app_instance_id;
    $self->$orig($item);
};






1;

__END__

=pod

=head1 NAME

Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance

=head1 SYNOPSIS

    package MyApp::API::Stuff;

    use Moose;
    use namespace::autoclean;

    extends 'DBIx::Class::API';
    with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';

    ...


=head1 DESCRIPTION

To be consumed by APIs whose resultset belongs to a AppInstance.

=head1 METHODS

=head2 restrict_by_app_instance

Restrict resultset by app_instance_id.

=head2 around _prepare_create_object

Automatically populates the app_instance_id column of each item being created.

=cut
