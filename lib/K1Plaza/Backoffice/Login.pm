package K1Plaza::Backoffice::Login;

use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Ref::Util qw/ is_blessed_ref is_plain_hashref /;



sub access_check {
    my $c = shift;

    # unauthenticated
    unless ($c->is_authenticated) {
        $c->redirect_to($c->url_for('login')->query(continue => $c->req->url->path->to_string)->to_abs);
        return;
    }

    # unauthorized
    my $user = $c->session->{__user};
    unless ($c->config->{backoffice_admins}{$user->{email}}) {
        $c->res->code(403);
        $c->render(text => "Access denied for $user->{email}");
        return;
    }

    return 1;
}


sub do_logout {
    my $c = shift;
    $c->logout;
    $c->redirect_to('/');
}


sub do_login {
    my $c = shift;
    my $params   = $c->req->query_params->to_hash;

    # login
    $c->log->debug("Initiating backoffice login via Google.");
    my $user = $c->_login_with_google();

    # failed, redirect to login
    unless (defined $user) {
        $c->log->debug("Backoffice login failed.");
        return $c->redirect_to($c->url_for('login')->query(continue => $c->req->url->path->to_string));
    }

    # redirect to url (OAuth login, or login via token, or connect-success)
    return $c->redirect_to("$user")
        if is_blessed_ref($user) && $user->isa('Mojo::URL');

    # at this point, $user should be a user object, after a successful authentication
    die "[Backoffice::Login] handler didn't return a google user hashref."
        unless is_plain_hashref($user) && $user->{google_id};

    # authentication success: connect account or login
    $c->log->debug("Successfull backoffice login: $user->{email}");

    $c->login($user);
    $c->redirect_to($params->{continue} || $c->session->{continue} || '/');
}


sub _login_with_google {
    my ($c) = @_;
    my $app = $c->app;
    my $api = $c->api("Google");
    my $params = $c->req->query_params->to_hash;

    my $callback_uri = $c->url_for('login');
    # $callback_uri->query(undef);
    $callback_uri = $callback_uri->to_abs->to_string;
    $c->log->debug("Redirect URL: $callback_uri");

    # response
    if (defined $params->{code}) {

        my $token = $api->request_access_token({
            code          => $params->{code},
            redirect_uri  => "$callback_uri"
        });

        unless ($token) {
            $c->log->debug("[Backoffice::Login] Failed to request Google access token.");
            return;
        }

        my $google_user = $api->request_token_user($token);
        # p $google_user;
        unless ($google_user) {
            $c->log->debug("[Backoffice::Login] Failed to fetch user from Google!");
            return;
        }

        return $google_user;
    }

    # initiate

    # save continue url in session since we cant use the 'continue' query parameter
    $c->session->{continue} = $params->{continue}
        if $params->{continue};

    $api->get_authentication_url({
        redirect_uri => "$callback_uri",
        state        => $c->req->headers->host, # TODO sign using hmac
    });
}




1;
