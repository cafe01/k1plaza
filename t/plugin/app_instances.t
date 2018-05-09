use Test::K1Plaza;
use Test::Mojo;


my $app = app();
my $t = Test::Mojo->new;
$t->app($app);

my $api = $app->api('AppInstance');
$api->register_app('foobarsite');


subtest 'detect app instance' => sub {

    $t->get_ok('/file.txt' => {'Host' => 'foobarsite'})
      ->status_is(200);

    $t->get_ok('/file.txt' => {'Host' => 'donotexist'})
      ->status_is(404);
};

subtest 'root page' => sub {

    $t->get_ok('/' => {'Host' => 'foobarsite'})
      ->status_is(200);

    $t->get_ok('/' => {'Host' => 'donotexist'})
      ->status_is(404);
};

subtest 'cdn host' => sub {

    app->config->{cdn_host} = 'supercdn';

    $t->get_ok('/foobarsite/file.txt' => {'Host' => app->config->{cdn_host} })
      ->content_is("ok\n")
      ->status_is(200);

    $t->get_ok('/donotexist/file.txt' => {'Host' => app->config->{cdn_host} })
      ->status_is(404);
};

subtest 'auth host' => sub {

    app->config->{auth_host} = 'authhost';

    $t->get_ok('/file.txt?domain=foobarsite' => {'Host' => app->config->{auth_host} })
      ->content_is("ok\n")
      ->status_is(200);

    $t->get_ok('/file.txt?domain=donotexist' => {'Host' => app->config->{auth_host} })
      ->status_is(404);
};




done_testing();
