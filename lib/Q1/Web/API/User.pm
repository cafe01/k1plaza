package Q1::Web::API::User;

use Moose;
use namespace::autoclean;
use utf8;
use Q1::Web::User;
use Data::Printer;
use Data::Dumper;

extends 'DBIx::Class::API';


with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance',
     'DBIx::Class::API::Feature::Sencha';


has '+dbic_class', default => 'User';
has '+use_json_boolean', default => '1';
has '+sortable_columns', default => sub { [qw/ me.first_name me.email me.last_login_at me.created_at /] };

has 'tx', is => 'ro';

has 'auto_create', is => 'rw', isa => 'Bool', default => 1;
has 'auto_update', is => 'rw', isa => 'Bool', default => 0;





before 'list' => sub {
    my ($self, $args) = (@_);
    return unless $args;

    # role
    if ($args->{role}) {
        $self->tx->log->debug("User API app instance: ".$self->app_instance_id);
        my $role = $self->tx->api('Role', { app_instance_id => $self->app_instance_id })->find_by_name($args->{role});

        if ($role) {
            $self->modify_resultset({ 'user_roles.role_id' => $role->id }, { join => 'user_roles' })
        }
        else {
            $self->modify_resultset(\'0=1')
        }
    }
};



sub with_icon {
	my ($self) = @_;

	$self->add_object_formatter(sub {
	    my ($self, $obj, $formatted) = @_;
	    $formatted->{icon} = $obj->icon;
	});

	$self;
}


sub _prepare_related_roles {
    my ($self, $raw) = @_;
    my $api = $self->tx->api('Role');
    $api->app_instance_id($self->app_instance_id);
    $api->find_or_create($raw);
}



sub from_facebook {
    my ($self, $token) = @_;
    my $tx = $self->tx;
    my $log = $tx->log;
    my $fb = $tx->api('Facebook', { token => $token });
    my $fb_user = $fb->request('me', { fields => 'id,first_name,last_name,email' });

    # invalid fb user
    unless ($fb_user->{email}) {
        $log->error("Failed to fetch facebook user.", Dumper $fb_user);
        return;
    }

    # format
    $fb_user->{facebook_id} = delete $fb_user->{id};
    $fb_user->{image_url} = "https://graph.facebook.com/v3.0/$fb_user->{facebook_id}/picture";

    my $user_obj = $self->find({ email => $fb_user->{email} })->first;

    if ($user_obj) {

        # update
        if ($self->auto_update) {
            $log->info("Auto-updating user '$fb_user->{email}' with facebook data: first_name=$fb_user->{first_name} last_name=$fb_user->{last_name} image_url=$fb_user->{image_url}");
            $user_obj->update($fb_user);
            $user_obj->discard_changes;
        }
        else {
            # update missing columns
            for (qw/ facebook_id first_name last_name image_url /) {
                $user_obj->set_column($_, $fb_user->{$_})
                    if !$user_obj->get_column($_) && $fb_user->{$_};
            }
            $user_obj->update;
        }

        return Q1::Web::User->new( _user => $user_obj );
    }

    # create
    return unless $self->auto_create;
    $user_obj = $self->create($fb_user)->first->{object};

    unless ($user_obj) {
        $log->error("Error while auto-creating user from Facebook: ".join("\n", $self->all_errors));
        return;
    }

    Q1::Web::User->new( _user => $user_obj );
}


sub from_google {
    my ($self, $token) = @_;

    my $google_user = $self->tx->api('Google')->request_token_user($token)
        or return;

    # find existing user
    my $user_obj = $self->find({ email => $google_user->{email} })->first;

    if ($user_obj) {

        # update
        if ($self->auto_update) {
            $self->tx->log->debug("Auto-updating user '$google_user->{email}' with google data: first_name=$google_user->{first_name} last_name=$google_user->{last_name} image_url=$google_user->{image_url}");
            $user_obj->update($google_user);
            $user_obj->discard_changes;
        }
        else {
            # update missing columns
            for (qw/ google_id first_name last_name image_url /) {
                $user_obj->set_column($_, $google_user->{$_})
                    if !$user_obj->get_column($_) && $google_user->{$_};
            }
            $user_obj->update;
        }

        return Q1::Web::User->new( _user => $user_obj );
    }

    # create
    return unless $self->auto_create;
    $user_obj = $self->create($google_user)->first->{object};

    unless ($user_obj) {
        $self->tx->log->error("Error while auto-creating user from Google: ".join("\n", $self->all_errors));
        return;
    }

    Q1::Web::User->new( _user => $user_obj );
}


sub from_session {
    my ($self, $frozenuser) = @_;
    my $tx = $self->tx;

    die "Can't inflate a session user: tx has no app instance set!"
        unless $tx->has_app_instance;

    return unless ref $frozenuser eq 'HASH';

    my $obj = $self->resultset->new_result({ %$frozenuser });
    $obj->in_storage(1);

    Q1::Web::User->new( _user => $obj );
}


sub from_token {
    my ($self, $token) = @_;
    my $tx  = $self->tx;

    # verify token
    my $user_id = $tx->verify_login_token($token);
    return unless $user_id;

    # fetch user
    my $user_obj = $tx->api('User')->find($user_id)->first;
    return unless $user_obj;

    # return web user
    Q1::Web::User->new( _user => $user_obj );
}



__PACKAGE__->meta->make_immutable();


1;
