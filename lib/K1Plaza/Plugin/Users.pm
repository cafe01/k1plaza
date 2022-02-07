package K1Plaza::Plugin::Users;

use Mojo::Base 'Mojolicious::Plugin';
use Data::Printer;
use DateTime;
use Mojo::Util qw/ hmac_sha1_sum b64_encode b64_decode /;
use Ref::Util qw/ is_plain_hashref /;

sub register {
    my ($c, $app) = @_;

    # routes
    $app->routes->get('/.logout' => sub {
        my $c = shift;
        $c->logout;
        $c->redirect_to('/');
    })->name('logout');

    # helpers
    $app->helper($_ => $c->can("_$_"))
        for qw/ login logout user user_exists is_authenticated redirect_to_login create_login_token verify_login_token /;
}


sub _login {
    my ($c, $user) = @_;

    $c->session->{__user} = is_plain_hashref $user ? $user : { $user->get_columns };
    return $c if is_plain_hashref $user;

    $user->update({ last_login_at => DateTime->now->strftime('%F %T') });
    $c->stash->{'k1plaza.user'} = $user
        if $user->isa('Q1::Web::User');
    $c;
}

sub _logout {
    my ($c) = @_;
    delete $c->session->{__user};
    $c;
}

sub _user_exists {
    my ($c) = @_;
    defined $c->session->{__user}
}

sub _is_authenticated {
    my ($c) = @_;
    defined $c->session->{__user}
}

sub _user {
    my ($c) = @_;
    return unless defined $c->session->{__user};

    unless ($c->stash->{'k1plaza.user'}) {
        $c->stash->{'k1plaza.user'} = $c->api('User')->from_session($c->session->{__user})
    }

    $c->stash->{'k1plaza.user'};
}

sub _redirect_to_login {
    my ($c, %opt) = @_;
    my $login_url = $c->url_for('login');
    $login_url->query({ continue => $c->req->url->path->to_string }) if $opt{continue};

    if (my $auth_host = $c->app->config->{auth_host}) {
        $login_url = $login_url->to_abs(Mojo::URL->new("https://$auth_host/"));
        $login_url->query([domain => $c->app_instance->current_alias]);
    }

    $c->redirect_to($login_url->to_abs);
}

sub _create_login_token {
    my ($c, $user) = @_;
    my $secret = $c->app->secrets->[0];

    die "Can't create login token! No app secret!"
        unless $secret;

    die "Can't create login token! No app instance loaded!"
        unless $c->has_app_instance;

    if (!$user) {
        die "Can't create login token! No user logged in!"
            unless $c->user_exists;

        $user = $c->user;
    }

    my $auth_data = join ':', $c->app_instance->id, $user->id, time, $c->tx->remote_address;
    my $signature = hmac_sha1_sum($auth_data, $secret);
    b64_encode($signature.$auth_data, '');
}


sub _verify_login_token {
    my ($c, $token) = @_;
    my $app_instance = $c->app_instance;
    my $secret = $c->app->secrets->[0];

    die "Can't verify login token! No app secret!"
        unless $secret;

    die "Can't verify login token! No app instance loaded!"
        unless $c->has_app_instance;

    $token //= $c->req->param('token');

    return unless $token;

    # check signature
    my ($signature, $data) = unpack "A40A*", b64_decode($token);
    unless ( $signature eq hmac_sha1_sum($data, $secret) ) {
        $c->log->error("login token signature '$signature' failed for payload '$data'");
        return;
    }

    my ($app_id, $user_id, $timestamp, $ipaddress) = split ':', $data;


    unless ( $app_id && $app_id == $app_instance->id
            && $timestamp < (time + 15)) {

        $c->log->warn(sprintf "failed to verify_login_token():\n"
            ."tok data: app=$app_id, timestamp=$timestamp, ip=$ipaddress, user=$user_id\n"
            ."req data: app=%s, timestamp=%s, ip=%s\n",
            $app_instance->id, time, $c->tx->remote_address);

        return;
    }

    $user_id;
}


1;
