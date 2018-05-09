package Q1::Web::API::Cloudflare;

use strict;
use warnings;
use v5.10;
use Carp qw/croak/;
use Moo;
use LWP::UserAgent;
use HTTP::Request;
use URI;
use JSON qw/ encode_json decode_json /;

has 'ua', is => 'ro', default => sub {
    my $ua = LWP::UserAgent->new;
    $ua->agent("Q1-Web-API-Cloudflare");
    return $ua;
};

has 'url_prefix', is => 'ro', default => sub { 'https://api.cloudflare.com/client/v4/' };
has 'email', is => 'ro', lazy => 1, default => sub { shift->app->config->{cloudflare}{api_user} || die 'Missing "cloudflare.api_user" app config.'};
has 'key', is => 'ro', lazy => 1,   default => sub { shift->app->config->{cloudflare}{api_key}  || die 'Missing "cloudflare.api_key" app config.' };
has 'user_service_key', is => 'ro';

sub request {
    my ($self, $method, $url, $params) = @_;

    croak '[Cloudflare] email and key are all required' unless $self->email and $self->key;

    my $headers = [
        'X-Auth-Email' => $self->email,
        'X-Auth-Key'   => $self->key,
        'Content-Type' => 'application/json',
    ];
    push(@$headers, 'X-Auth-User-Service-Key' => $self->user_service_key)
        if $self->user_service_key;

    $url = '/' . $url unless $url =~ m{^/};
    $url = $self->url_prefix . $url;

    my $body;
    if ($method eq 'GET') {
        my $uri = URI->new($url);
        $uri->query($params);
        $url = "$uri";
    } elsif (grep { $method eq $_ } ('POST', 'PUT', 'PATCH', 'DELETE')) {
        $body = encode_json $params;
    }

    my $request = HTTP::Request->new(uc $method, $url, $headers, $body || ());
    my $res = $self->ua->request($request);

    # error
    unless ($res->is_success) {
        croak $res->status_line;
    }

    decode_json $res->content;
}

1;
