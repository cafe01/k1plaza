use Test::K1Plaza;
use Test::Mojo;


my $app = app();
my $t = Test::Mojo->new;
$t->app($app);
$app->schema->deploy({ add_drop_table => 1 });

my $api = $app->api('AppInstance');
$api->register_app('foobarsite');


subtest 'success' => sub {

    my $form = {
        name => "Cafe",
        email => 'cafe@email.com',
        _csrf => '123'
    };

    $t->post_ok('/.form/welcome' => {'Host' => 'foobarsite', 'Accept' => 'application/json' } => json => $form )
      ->status_is(200)
      ->json_is('/success', 1)
      ->json_is('/data/name', $form->{name});

    # p $t->tx->res->json;
};

subtest 'error' => sub {

    my $form = {
        name => "Cafe",
        email => 'cafe@email.com',
    };

    $t->post_ok('/.form/welcome' => {'Host' => 'foobarsite', 'Accept' => 'application/json' } => json => $form )
      ->status_is(200)
      ->json_is('/success', 0)
      ->json_is('/errors/0/field', "_csrf")
      ->json_is('/errors/0/message', "Campo obrigatório");

    # p $t->tx->res->json;
};

done_testing;
