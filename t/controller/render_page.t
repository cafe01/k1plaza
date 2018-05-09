use Test::K1Plaza;
use Test::Mojo;


my $app = app();
my $t = Test::Mojo->new;
$t->app($app);

my $api = $app->api('AppInstance');
$api->register_app('foobarsite');
$api->register_app('dynamicsite');


subtest 'render foobarsite/index' => sub {

    $t->get_ok('/index' => {'Host' => 'foobarsite'})
      ->text_is('title' => 'Início - Foobarsite')
      ->text_is('h1' => 'Hello K1Plaza')
      ->status_is(200);

    $t->get_ok('/' => {'Host' => 'foobarsite'})
      ->text_is('title' => 'Início - Foobarsite')
      ->text_is('h1' => 'Hello K1Plaza')
      ->status_is(200);
};

subtest 'render dynamicsite/index' => sub {

    $t->get_ok('/' => {'Host' => 'dynamicsite'})
      ->text_is('title' => 'dynamicsite')
      ->text_is('h1' => 'Hello Dynamic Page')
      ->status_is(200);

};




done_testing();
