use Test::K1Plaza;
use Test::Mojo;
use Mojolicious::Command::routes;

use re 'regexp_pattern';
use Mojo::Util qw(encode getopt tablify);

# my $app = app();
my $t = Test::Mojo->new;
$t->app(app());

my $c = app->build_controller;
my $api = app->api('AppInstance');
($c->stash->{__app_instance}) = $api->_instantiate_app_instance($api->register_app('foobarsite'));


isa_ok $c->sitemap, 'K1Plaza::Sitemap';
 # diag_routes($c->sitemap);

subtest 'root page' => sub {

    $t->get_ok('/' => {'Host' => 'foobarsite'})
      ->status_is(200);
};


subtest 'widget args' => sub {

    $t->get_ok('/artigos' => {'Host' => 'foobarsite'})
      ->status_is(200)
      ->element_count_is('article', 3);

    $t->get_ok('/artigos/id/1' => {'Host' => 'foobarsite'})
      ->status_is(200)
      ->element_count_is('article', 1);
};


subtest 'inner page' => sub {

    $t->get_ok('/path' => {'Host' => 'foobarsite'})
      ->status_is(404);

    $t->get_ok('/path/foo/' => {'Host' => 'foobarsite'})->status_is(200)->element_count_is('h1.inner-page', 1);
    $t->get_ok('/path/bar' => {'Host' => 'foobarsite'})->status_is(200)->element_count_is('h1.inner-page', 1);
    # diag $t->tx->res->body;
    $t->get_ok('/path/bar/baz/' => {'Host' => 'foobarsite'})->status_is(200)->element_count_is('h1.inner-page', 1);
};


subtest 'locale - inner page' => sub {

    $t->get_ok('/en/path' => {'Host' => 'foobarsite'})
      ->status_is(404);

    $t->get_ok('/en/path/foo/' => {'Host' => 'foobarsite'})
      ->status_is(200)
      ->element_count_is('h1.with-locale', 1);

    $t->get_ok('/en/path/bar' => {'Host' => 'foobarsite'})->status_is(200)->element_count_is('h1.with-locale', 1);
    $t->get_ok('/en/path/bar/baz/' => {'Host' => 'foobarsite'})->status_is(200)->element_count_is('h1.with-locale', 1);
};

subtest 'page tree' => sub {

    my $tree = $c->sitemap->page_tree;
    is @$tree, 3;
    is $tree->[2]{children}[1]{children}[0]{fullpath}, 'path/bar/baz';
};


subtest 'from_dir' => sub {

    ($c->stash->{__app_instance}) = $api->_instantiate_app_instance($api->register_app('dynamicsite'));

    # diag_routes($c->sitemap);

    $t->get_ok('/' => {'Host' => 'dynamicsite'})
      ->status_is(200)
      ->element_count_is('title', 1);

    $t->get_ok('/inner' => {'Host' => 'dynamicsite'})
      ->status_is(404);

    $t->get_ok('/inner/page' => {'Host' => 'dynamicsite'})
      ->status_is(200)
      ->element_count_is('h1', 1);
};





sub diag_routes {
    my $routes = shift;
    my $rows = [];
    Mojolicious::Command::routes::_walk($_, 0, $rows, 1) for @{$routes->children};
    diag encode('UTF-8', tablify($rows));
}

done_testing;
