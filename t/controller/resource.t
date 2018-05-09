use Test::K1Plaza;
use Test::Mojo;


my $app = app();
my $t = Test::Mojo->new;
$t->app($app);

my $c = app->build_controller;
($c->stash->{__app_instance}) = app->api('AppInstance')->register_app('foobarsite');
my $user = $c->api("User")->create({ first_name => 'admin', roles => ['instance_admin'], email => 'admin@q1plaza.dev' })->first->{object};


our $LOGIN = 1;
app->hook(before_dispatch => sub {
    my $c = shift;
    $LOGIN ? $c->login($user) : $c->logout;
});

subtest 'create app resource' => sub {

    $t->post_ok('/.resource/tag?widget=blog' => {'Host' => 'foobarsite'} => json => { name => 'Tag01' })
      ->json_is('/success', 1)
      ->json_is('/items/0/name', 'Tag01')
      ->status_is(200);

    $t->post_ok('/.resource/tag?widget=blog&redirect=1' => {'Host' => 'foobarsite'} => json => { name => 'Tag02' })
      ->content_is('')
      ->header_is(Location => '/.resource/tag/2?widget=blog&redirect=1')
      ->status_is(303);

   # p $t->tx->res->json;

   # login
   local $LOGIN = 0;
   $t->post_ok('/.resource/tag?widget=blog' => {'Host' => 'foobarsite'})
     ->status_is(403);
};

subtest 'list app resource' => sub {

    $t->get_ok('/.resource/tag' => {'Host' => 'foobarsite'})
      ->status_is(400, 'missing widget param');

    $t->get_ok('/.resource/tag?widget=blog&limit=100&page=1' => {'Host' => 'foobarsite'})
      ->json_is('/success', 1)
      # ->json_is('/total', 1)
      ->json_is('/entries_per_page', 100)
      ->status_is(200);
};

subtest 'list single resource' => sub {

    $t->get_ok('/.resource/tag/1?widget=blog' => {'Host' => 'foobarsite'})
      ->json_is('/name', 'Tag01')
      ->status_is(200);

    $t->get_ok('/.resource/tag/1?widget=blog&envelope=1' => {'Host' => 'foobarsite'})
      ->json_is('/success', 1)
      ->json_is('/items/name', 'Tag01')
      ->status_is(200);
};

subtest 'update app resource' => sub {

    $t->put_ok('/.resource/tag/1?widget=blog' => {'Host' => 'foobarsite'} => json => { slug => 'tag-01' })
      ->json_is('/success', 1)
      ->json_is('/items/0/name', 'Tag01')
      ->status_is(200);

    # redirect
    $t->put_ok('/.resource/tag/1?widget=blog&redirect=1' => {'Host' => 'foobarsite'} => json => { slug => 'tag01' })
      ->header_is(Location => '/.resource/tag/1?widget=blog&redirect=1')
      ->status_is(303);

   # p $t->tx->res->json;
};

subtest 'delete app resource' => sub {

    $t->delete_ok('/.resource/tag/1?widget=blog' => {'Host' => 'foobarsite'})
      ->status_is(204);

    is app->schema->resultset('Tag')->count({id => 1}), 0, 'deleted';
};



done_testing();
