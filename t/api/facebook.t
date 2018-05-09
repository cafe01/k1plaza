
use Test::K1Plaza;

app->config->{facebook} = {
    app_id => $ENV{FACEBOOK_APP_ID},
    app_secret => $ENV{FACEBOOK_APP_SECRET}
};

my $api = app->api('Facebook');


subtest 'test_authorization_url' => sub {

    my $params = { permissions => 'email', display => 'popup', callback => 'http://example.com/foo'};
    is $api->get_authorization_url($params), 'https://graph.facebook.com/oauth/authorize?redirect_uri=http%3A%2F%2Fexample.com%2Ffoo&client_id=1383160611915407&scope=email&display=popup', 'get_authorization_url';
};

subtest 'request' => sub {

    skip_all "missing FACEBOOK_TOKEN" unless $ENV{FACEBOOK_TOKEN};
    $api->token($ENV{FACEBOOK_TOKEN});
    my $me = $api->request('me', { fields => 'id,first_name,last_name,email' });
    is $me->{id}, '100006604867737', 'request("me") id';
    is $me->{email}, 'cafe01@gmail.com', 'request("me") email';

};

# sub test_request {
#
#     my $api = $tx->api('Facebook', { token => $ENV{FACEBOOK_TOKEN} });
#
#     is $api->request('me')->{id}, '100006604867737', 'request("me")';
#
#     is $api->request('0'), undef, 'request("0") return undef on error';
#
#     like $api->request_long_token, qr/\w+/, 'request_long_token';
#
# }


done_testing();
