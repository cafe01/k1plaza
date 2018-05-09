#!/usr/bin/env perl
use Test::K1Plaza;

my $app = app();
my $api = $app->api('Instagram');

# skip
my ($client_id, $client_secret) = @{app->config->{instagram}}{qw/ client_id client_secret /};
unless( $client_id && $client_secret ) {
    plan skip_all => 'Missing required app config instagram.client_id and instagram.client_secret';
}

test_api();
test_get_medias_by_tag();
# test_get_user_medias();

done_testing;





sub test_api {

    my $api = $app->api('Instagram', { client_id => $client_id, client_secret => $client_secret });
    isa_ok $api, 'Q1::Web::API::Instagram';
}



sub test_get_medias_by_tag {

    my $api = $app->api('Instagram', { client_id => $client_id, client_secret => $client_secret });
    my $res = $api->get_medias_by_tag('sushitripdelivery');
    p $res;
    # diag Dumper $res;
    # is $res->{meta}{code}, 200, 'test_get_medias_by_tag';
}


sub test_get_user_medias {

    my $api = $app->api('Instagram', { client_id => $client_id, client_secret => $client_secret });
    my $res = $api->get_user_medias('sushitripdelivery');
    is ref $res->[0], 'HASH', '1st response item is a hashref';
    like $res->[0]{display_src}, qr/^http/, 'display_src';
    like $res->[0]{thumbnail_src}, qr/^http/, 'thumbnail_src';
}
