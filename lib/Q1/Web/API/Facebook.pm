package Q1::Web::API::Facebook;

use Moo;
use namespace::autoclean;
use URI;
use JSON qw/from_json/;


has 'tx', is => 'ro', required => 1;

has 'api_version', is => 'ro', default => 'v3.0';

has 'app_id', is => 'rw';

has 'app_secret', is => 'rw';

has 'callback', is => 'rw';

has 'token', is => 'rw';




sub BUILD {
    my ($self) = @_;

    my $tx = $self->tx;
    my $app_instance_config = $tx->has_app_instance ? $tx->app_instance->config : {};

    my $fb_config = $app_instance_config->{facebook} ? $app_instance_config->{facebook}
                                                     : $tx->config->{facebook};

    return die "[API::Facebook] App não possui as configuraçoes 'facebook.app_id' e 'facebook.app_secret'"
        unless $fb_config && $fb_config->{app_id} && $fb_config->{app_secret};

    $self->app_id($fb_config->{app_id});
    $self->app_secret($fb_config->{app_secret});
}


sub get_authorization_url {
    my ($self, $params) = @_;

    $params->{callback} ||= $self->callback;
    die "[API::Facebook] get_authorization_url(): missing 'callback' parameter"
        unless $params->{callback};

    # https://graph.facebook.com/oauth/authorize?redirect_uri=http%3A%2F%2Fexample.com%2Ffoo&client_id=1383160611915407&scope=email&display=popup
    my $uri = URI->new('https://graph.facebook.com/oauth/authorize');
    $uri->query_form(
        redirect_uri => $params->{callback},
        client_id    => $self->app_id,
        scope        => $params->{permissions} || 'public_profile,email',
        display      => $params->{display} || 'page',
    );

    $uri;
}


sub request_access_token {
    my ($self, $code, $callback) = @_;
    my $tx = $self->tx;
    $callback ||= $self->callback;
    die "[API::Facebook] request_access_token(): missing 'callback' parameter"
        unless $callback;

    my $uri = URI->new('https://graph.facebook.com/oauth/access_token');
    $uri->query_form(
        redirect_uri  => $callback,
        client_id     => $self->app_id,
        client_secret => $self->app_secret,
        code          => $code
    );

    my $res = $tx->ua->get("$uri")->result;
    unless ($res->is_success) {
        $tx->log->error("[Facebook] request_access_token($uri): http code: ".$res->code."\n".$res->body);
        return;
    }

    $res->json->{access_token};
}


sub request {
    my ($self, $endpoint, $params) = @_;
    my $tx = $self->tx;

    # build url
    my $url = Mojo::URL->new('https://graph.facebook.com/'.$self->api_version."/$endpoint");
    $url->query(
        %{ $params||{} },
        access_token => $self->token
    );

    # fetch
    my $res = $tx->ua->get($url)->result;
    unless ($res->is_success) {
        $tx->log->error("[Facebook] request($url): error: ".$res->message, $res->body);
        return;
    }

    $res->json;
}


sub request_long_token {
    my ($self) = @_;
    my $tx = $self->tx;

    die "[API::Facebook] request_long_token(): no token set yet!"
        unless $self->token;

    my $uri = URI->new('https://graph.facebook.com/oauth/access_token');
    $uri->query_form(
        grant_type        => 'fb_exchange_token',
        client_id         => $self->app_id,
        client_secret     => $self->app_secret,
        fb_exchange_token => $self->token
    );

    my $res = $tx->ua->get($uri);
    unless ($res->is_success) {
        $tx->log->error("[API::Facebook] request_long_token(): http error for url '$uri': ".$res->status_line);
        return;
    }

    my ($token) = $res->content =~ /access_token=(\w+)(?:&|$)/;
    $token;

}


1;

__END__

=pod

=head1 NAME

Q1::Web::API::Facebook

=head1 DESCRIPTION

=cut
