use Mojo::Base -strict;

use Test2::V0;
use Test::Mojo;

my $t = Test::Mojo->new('TestApp');
my $app = $t->app;

isa_ok $app->apis, 'K1Plaza::Apis';
is $app->apis->namespaces, ['TestApp::API'], 'namespaces';
isa_ok $app->api('Dummy'), 'TestApp::API::Dummy';
is $app->api('Dummy')->foo, 'bar', 'api method';





done_testing();







{
    package TestApp;
    use Mojo::Base 'Mojolicious';

    # This method will run once at server start
    sub startup {
      my $self = shift;

      $self->plugin('K1Plaza::Plugin::Apis');
    }



    package TestApp::API::Dummy;
    use Mojo::Base '-base';

    sub foo { 'bar' }
}
