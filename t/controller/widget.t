use Test::K1Plaza;
use Test::Mojo;


my $t = Test::Mojo->new;
$t->app(app());

# prepare app instance
my $c = app->build_controller;
($c->stash->{__app_instance}) = app->api('AppInstance')->register_app('foobarsite');
my $user = $c->api("User")->create({ first_name => 'admin', roles => ['instance_admin'], email => 'admin@q1plaza.dev' })->first->{object};


our $LOGIN = 1;
app->hook(before_dispatch => sub {
    my $c = shift;
    $LOGIN ? $c->login($user) : $c->logout;
});


subtest 'create_resource' => sub {

    $t->post_ok('/.widget/blog?envelope=1' => {'Host' => 'foobarsite'} => json => { title => 'Novo Post' })
      ->content_is('')
      ->header_is(Location => '/.widget/blog/4?envelope=1')
      ->status_is(303);
};

subtest 'update resource' => sub {

    $t->put_ok('/.widget/blog/4' => {'Host' => 'foobarsite'} => json => { content => 'some content', is_published => 1 })
      ->status_is(204);
};

subtest 'list' => sub {

    $t->get_ok('/.widget/blog' => {'Host' => 'foobarsite'})
      ->json_is('/success', 1)
      ->json_is('/total', 4)
      ->status_is(200);

    # login
    local $LOGIN = 0;
    $t->get_ok('/.widget/blog' => {'Host' => 'foobarsite', 'X-Requested-With' => 'XMLHttpRequest'})
      ->content_is('')
      ->status_is(403);

};

subtest 'list_single' => sub {

    $t->get_ok('/.widget/blog/4' => {'Host' => 'foobarsite'})
      ->json_is('/title', 'Novo Post')
      ->status_is(200);

    $t->get_ok('/.widget/blog/4?envelope=1' => {'Host' => 'foobarsite'})
      ->json_is('/success', 1)
      ->json_is('/items/title', 'Novo Post')
      ->json_is('/items/content', 'some content')
      ->status_is(200);

};

subtest 'delete resource' => sub {

    $t->delete_ok('/.widget/blog/1' => {'Host' => 'foobarsite'})
      ->status_is(204);
};





done_testing;
