package K1Plaza::Resource::Sitemap;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;



sub list  {
    my $c = shift;
    my $sitemap = $c->api('Data')->get('sitemap') || $c->app_instance->config->{sitemap} || {};
    $c->render(json => $sitemap);
}

sub create {
    my $c = shift;
    $c->api('Data')->set('sitemap', $c->req->json);
    $c->rendered(204);
}

1;
