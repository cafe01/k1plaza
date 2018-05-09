use Test::K1Plaza;

my $app = app();

my $api = $app->api('AppInstance');
isa_ok $api, 'Q1::API::AppInstance';


subtest 'register_app' => sub {

    my $res = $api->register_app('foobarsite');

    like $res->{items}[0], {
        canonical_alias => 'foobarsite',
        is_managed => 0,
        uuid => qr/\w+/
    };
};

subtest 'instantiate_by_alias' => sub {

    my $app_instance = $api->instantiate_by_alias('foobarsite');

    isa_ok $app_instance, 'Q1::AppInstance';
    isa_ok $app_instance->base_dir, 'Mojo::File';
    is $app_instance->base_dir, app->home->child('app_instances/foobarsite')->to_abs;

    like $app_instance->config, {
        sitemap => {
            root => 'index'
        }
    };
};




done_testing();
