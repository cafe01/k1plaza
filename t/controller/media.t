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


subtest 'upload' => sub {

    my $file = app->home->child('share/image.png');
    my $upload = { file => {
        content => $file->slurp,
        filename => $file->basename
    }};

    $t->post_ok('/.media?envelope=1' => {'Host' => 'foobarsite'} => form => $upload )
      ->header_is(Location => '/.media/1?envelope=1')
      ->status_is(303);

    local $LOGIN = 0;
    $t->post_ok('/.media' => {'Host' => 'foobarsite'} => form => $upload )
      ->status_is(403);

    # diag $t->tx->res->body;
};


subtest 'list' => sub {

    $t->get_ok('/.media?limit=100' => {'Host' => 'foobarsite'})
      ->json_is('/success', 1)
      ->json_is('/total', 1)
      ->json_is('/entries_per_page', 100)
      ->json_like('/items/0/url', qr!/\.media/file/\w+\.png!)
      ->status_is(200);

    # diag $t->tx->res->body;
};

subtest 'list_single' => sub {

    $t->get_ok("/.media/1?envelope=1" => {'Host' => 'foobarsite'})
      ->json_is('/success', 1)
      ->json_is('/items/id', 1)
      ->status_is(200);

    $t->get_ok("/.media/1" => {'Host' => 'foobarsite'})
      ->json_is('/id', 1)
      ->status_is(200);

    # diag $t->tx->res->body;
};


subtest 'update' => sub {

    my $res = $c->api('Media')->create({ file => app->home->child('share/image.png')->to_string })->result;
    my $id = $res->{items}[0]{id};

    $t->put_ok("/.media/$id" => {'Host' => 'foobarsite'} => json => { file_name => 'newname.png' })
      ->json_is('/success', 1)
      ->json_is('/items/0/file_name', 'newname.png')
      ->status_is(200);
};


subtest 'delete' => sub {

    my $res = $c->api('Media')->create({ file => app->home->child('share/image.png')->to_string })->result;
    my $id = $res->{items}[0]{id};

    $t->delete_ok("/.media/$id" => {'Host' => 'foobarsite'})
      ->json_is('/success', 1)
      ->status_is(200);

    # p $t->tx->res->json;
    is $c->api('Media')->count({ id => $id }), 0, 'deleted';
};


subtest 'reposition' => sub {

    $t->post_ok("/.media/reposition" => {'Host' => 'foobarsite'})
      ->status_is(400);

    # p $t->tx->res->json;
};


subtest 'fetch file' => sub {

    my $res = $c->api('Media')->create({ file => app->home->child('share/image.png')->to_string })->result;
    my $uuid = $res->{items}[0]{uuid};

    $t->get_ok("/.media/file/$uuid.png" => {'Host' => 'foobarsite'})
      ->content_type_is('image/png')
      ->header_is('Content-Disposition', undef)
      ->status_is(200);

    $t->get_ok("/.media/file/$uuid.png?download=1" => {'Host' => 'foobarsite'})
      ->content_type_is('image/png')
      ->header_is('Content-Disposition', 'attachment; filename=image.png;')
      ->status_is(200);
};

done_testing;
