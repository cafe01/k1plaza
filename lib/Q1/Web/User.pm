package Q1::Web::User;

use Moose;
use namespace::autoclean;

#use List::MoreUtils 'all';
use Try::Tiny;
use Carp ();



has '_user' => (is => 'rw', predicate => '_has_user');

has '_roles' => (
    is => 'rw',
    isa => 'ArrayRef',
    traits => ['Array'],
    lazy => 1,
    default => sub {
        my $self = shift;
        return [] unless $self->_user;
        [map { $_->rolename } $self->_user->roles];
    },
    handles => {
        roles => 'elements'
    }
);

sub check_any_roles {
    my ($self, @roles) = @_;
    return unless $self->_has_user;

    foreach my $role ($self->roles) {
        return 1 if grep { $_ eq $role } @roles;
    }

    return 0;
}

sub check_roles {
    my ($self, @roles) = @_;

    return unless $self->_has_user;

    my $has_all_roles = 1;
    my @user_roles    = $self->roles;

    foreach my $role (@roles) {
        $has_all_roles &&= grep { $_ eq $role } @user_roles;
    }

    return $has_all_roles;
}



sub get {
    my ($self, $field) = @_;

    if (my $code = $self->_user->can($field)) {
        return $self->_user->$code;
    }
    elsif ($self->_user->has_column($field)) {
        return $self->_user->get_column($field);
    }

    die "[Q1::Web::User] called get('$field'), but user object does not have this method or column.";
}

sub get_object {
    my ($self, $force) = @_;
    $self->_user->discard_changes if $force;
    return $self->_user;
}

sub obj {
    shift->get_object(@_);
}

sub AUTOLOAD {
    my $self = shift;
    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";
    Carp::confess "[Q1::Web::User] can't AUTOLOAD method '$method'"
        unless $self->_user && $self->_user->can($method);
    $self->_user->$method(@_)
}

__PACKAGE__->meta->make_immutable;

1;


1;
