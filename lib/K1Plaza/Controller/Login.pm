package K1Plaza::Controller::Login;

use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Ref::Util qw/ is_blessed_ref /;



sub do_logout {
    my $c = shift;
    $c->logout;
    $c->redirect_to('/');
}


sub do_login {
    my $c = shift;
    my $params   = $c->req->query_params->to_hash;
    my $provider = $params->{provider} || '';

    my $login_method = $provider =~ /^(facebook|google|token)$/ ? '_login_with_'.$provider : '';

    # $c->log->debug(sprintf "[Login] method: %s, host: %s, is_auth_host: %s", $login_method, $c->req->uri->host, $c->is_auth_host);

    # invalid access: has auth host but acessing directly for non token login
    if ($c->app->config->{auth_host} && (! $c->is_auth_host) && $provider ne 'token') {
        $c->log->warn('invalid access: has auth host but acessing directly for non token login');
        $c->redirect_to_login;
    }

    # show login page if no provider chosen
    return $c->render( template => 'login' )
        unless $login_method;

    # login
    $c->log->debug("Initiating login via: $provider");
    my $user = $c->$login_method();

    # failed, redirect to login
    unless (defined $user) {
        $c->log->debug("Failed authentication via $provider.");
        return $c->redirect_to_login;
    }

    # redirect to url (OAuth login, or login via token, or connect-success)
    return $c->redirect_to("$user")
        if is_blessed_ref($user) && $user->isa('Mojo::URL') || $user->isa('URI');

    # at this point, $user should be a user object, after a successful authentication
    die "[Controller::Login] authentication handlers must return undef, URI or User object. '$login_method' returned this: $user"
        unless is_blessed_ref($user) && $user->isa('Q1::Web::User');

    # authentication success: connect account or login
    $c->log->debug("Successfully authenticated via $provider.");

    # log user in or redirect to login via token on auth host
    if ($c->is_auth_host) {
        $c->log->debug("Initiating login via token.");
        return $c->redirect_to($c->_uri_for_token_login($user));
    }

    $c->log->debug("Completing login via $provider.");
    $c->login($user);
    $c->redirect_to($params->{continue} || $c->session->{continue} || '/');
}


sub _login_with_token {
    my ($c) = @_;
    $c->api('User')->from_token($c->req->param('token'));
}


sub _login_with_facebook {
    my $c = shift;
    my $params = $c->req->query_params->to_hash;

    my $callback_uri = $c->url_with(
        provider => 'facebook',
        continue => $params->{continue},
        domain   => $params->{domain}
    )->to_abs;

    my $facebook = $c->api('Facebook', { callback => "$callback_uri" });

    # initiate
    return $facebook->get_authorization_url({ permissions => 'public_profile,email', display => 'page' })
        unless defined $params->{code};

    # response
    my $token = $facebook->request_access_token($params->{code});
    unless ($token) {
        $c->log->debug("[Controller::Login] Failed to request Facebook access token.");
        return;
    }

    # create/update user for login
    $c->api('User')->from_facebook($token);

}


sub _login_with_google {
    my ($c) = @_;
    my $app = $c->app;

    my $params = $c->req->query_params->to_hash;
    my $app_instance = $c->app_instance;

    my ($client_id, $client_secret) =  ($app->config->{google}{client_id}, $app->config->{google}{client_secret});

    die ("Login via Google desativado. Faltando configurações do google oauth client.")
        unless $client_id && $client_secret;

    my $callback_uri = $c->req->url->clone->query( provider => 'google' )->to_abs;

    # response
    my $google = $c->api('Google');
    if (defined $params->{code}) {

        my $token = $google->request_access_token({
            code          => $params->{code},
            redirect_uri  => "$callback_uri",
        });

        unless ($token) {
            $c->log->debug("[Controller::Login] Failed to request Google access token.");
            return;
        }

        return $c->api('User')->from_google($token);
    }

    # initiate

    # save continue url in session since we cant use the 'continue' query parameter
    $c->session->{continue} = $params->{continue}
        if $params->{continue};

    my $auth_url = Mojo::URL->new('https://accounts.google.com/o/oauth2/auth');
    $auth_url->query({
        client_id       => $client_id,
        response_type   => 'code',
        scope           => 'email profile',
        redirect_uri    => "$callback_uri",
        state           => $app_instance->current_alias, # TODO sign using hmac
    });

    $auth_url;
}


sub _uri_for_token_login {
    my ($c, $user) = @_;

    my $uri = $c->url_for('login')->to_abs(Mojo::URL->new("http://".$c->app_instance->current_alias));
    $uri->query(
        provider => 'token',
        continue => $c->req->param('continue') || delete $c->session->{continue},
        token => $c->create_login_token($user)
    );

    $uri;
}
1;
