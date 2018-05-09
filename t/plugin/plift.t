use Test::K1Plaza;
use Test::Mojo;


my $app = app();
my $t = Test::Mojo->new;
$t->app($app);

my $api = $app->api('AppInstance');
$api->register_app('foobarsite');


subtest 'render index' => sub {

    $app->routes->get('/' => {
        template => 'page/index',
        handler  => 'plift',
        title    => 'Início'
    });

    $t->get_ok('/' => {'Host' => 'foobarsite'})
      ->text_is('title' => 'Início - Foobarsite')
      ->text_is('h1' => 'Hello K1Plaza')
      ->status_is(200);
};




done_testing();
