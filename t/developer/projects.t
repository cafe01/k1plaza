#!/usr/bin/env perl
use Test::K1Plaza;

my $app = app();
my $api = $app->api('Developer::Project');


subtest 'list' => sub {

    my $res = $api->list;
    # p $res;
    my $item = $res->{items}[0];
    like $item->{name}, qr/^\w+$/, 'name';
    is $item->{base_dir}, "/projects/$item->{name}", 'base_dir';
    # ok $res->{total} > 0, 'total';


};


done_testing;
