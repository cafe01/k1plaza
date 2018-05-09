package K1Plaza::API::Google;

use Mojo::Base -base;
use Mojo::URL;
use Carp qw/ confess /;

has 'app';
has 'client_id'     => sub { shift->app->config->{google}{client_id} || die 'Missing "google.client_id" app config.' };
has 'client_secret' => sub { shift->app->config->{google}{client_secret} || die 'Missing "google.client_secret" app config.' };



sub get_authentication_url {
    my ($self, $params) = @_;
    my $auth_url = Mojo::URL->new('https://accounts.google.com/o/oauth2/auth');

    $auth_url->query({
        client_id       => $self->client_id,
        response_type   => 'code',
        scope           => 'email profile',
        %$params
    });

    $auth_url;
}

sub request_access_token {
    my ($self, $params) = @_;

    $params->{grant_type} = 'authorization_code';
    $params->{client_id} = $self->client_id;
    $params->{client_secret} = $self->client_secret;

    my $res = $self->app->ua->post('https://accounts.google.com/o/oauth2/token' => form => $params)->result;

    unless ($res->is_success) {
        $self->tx->log->debug("[Google] request_access_token() HTTP error: ".$res->message, $res->body);
        return;
    }

    $res->json->{access_token};
}

sub request_token_user {
    my ($self, $token) = @_;
    my $res = $self->app->ua->get('https://www.googleapis.com/plus/v1/people/me?fields=id,name,image,emails' => { Authorization => "Bearer $token" })->result;

    unless ($res->is_success) {
        $self->app->log->debug("[Google] request_token_user() HTTP error: ".$res->message, $res->body);
        return;
    }

    my $data = $res->json;
    return unless $data;

    return {
        google_id  => $data->{id},
        first_name => $data->{name}{givenName},
        last_name  => $data->{name}{familyName},
        image_url  => $data->{image}{url},
        email      => $data->{emails}[0]{value}
    };
}


1;
