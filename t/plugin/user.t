use Test::K1Plaza;
use Test::Mojo;


# my $app = app();
my $t = Test::Mojo->new;
$t->app(app());

my $c = app->build_controller;
($c->stash->{__app_instance}) = app->api('AppInstance')->register_app('foobarsite');


my $user = $c->api("User")
             ->create({ first_name => 'admin', roles => ['instance_admin'], email => 'admin@q1plaza.dev' })
             ->first->{object};

subtest 'redirect_to_login' => sub {

    $t->get_ok('/.backend' => {'Host' => 'foobarsite'})
      ->header_is( Location => '/.login?continue=%2F.backend')
      ->status_is(302);

    # authhost
    app->config->{auth_host} = 'authhost';

    $t->get_ok('/.backend' => {'Host' => 'foobarsite'})
      ->header_is( Location => 'http://authhost/.login?continue=%2F.backend&domain=foobarsite')
      ->status_is(302);
};


subtest 'login token' => sub {

    $c->tx->remote_address("1.2.3.4");

    my $token = $c->create_login_token($user);

    like $token, qr/\w+/, 'create_login_token()';

    is $c->verify_login_token($token), $user->id, 'verify_login_token()';


    $c->tx->remote_address("10.20.30.40");
    is $c->verify_login_token($token), undef, 'verify_login_token() - changed IP';


};


done_testing();
