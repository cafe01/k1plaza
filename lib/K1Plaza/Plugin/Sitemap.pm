package K1Plaza::Plugin::Sitemap;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/steady_time/;
use Mojo::Cache;
use Mojolicious::Routes::Route;
use Data::Printer;
use K1Plaza::Sitemap;
# use strictures;

use feature qw(signatures postderef current_sub);
no warnings qw(experimental::signatures experimental::postderef);


my $CACHE;

sub register {
    my ($self, $app) = @_;

    $CACHE = Mojo::Cache->new(max_keys => $app->config->{sitemap_cache_size} // 0);

    # helpers
    $app->helper(sitemap => sub {
        my $c = shift;
        return if $c->stash->{'mojox.facet'} || !$c->has_app_instance;
        my $app_instance = $c->app_instance;
        my $key = join '', $app_instance->id, $app_instance->deployment_version || '-', $app_instance->config->{skin} || '-';
        my $sitemap = $CACHE->get($key);
        unless ($sitemap) {
            $sitemap = _build_sitemap($c);
            $CACHE->set($key, $sitemap);
        }
        $sitemap;
    });

    $app->helper(captures => sub {
        my $c = shift;
        # p $c->match->stack;
        $c->match->stack->[-1];
    });

    $app->helper( uri_for_page => sub {
        my ($c, $page) = @_;
        $page //= $c->stash;

        die "uri_for_page() error: no page suplied and I can't find one from current route!"
            unless exists $page->{fullpath};

        # my $default_locale = $self->app->config->{default_locale} || 'pt_BR';
        # $self->uri_for($self->locale eq $default_locale ? $page->{fullpath} : $self->locale.'/'.$page->{fullpath}, @_);
        my $url = $c->url_for($page->{fullpath})->to_abs;
        $url;
    });

    $app->helper( site_url_for => sub {
        my ($c, $route_name) = (shift, shift);
        my ($args, $query) = ref $_[0] eq 'ARRAY' ? (undef, $_[0]) : @_;
        $route_name = $c->match->endpoint->name if !$route_name || $route_name eq 'current';

        my $website = $c->app->routes->find('website') or return;
        my $route = $website->find($route_name) or return;
        my $url = $c->url_for( $route->render($args) );
        $url->query($query) if $query;
        $url;
    });
}

sub _build_sitemap {
    my ($c) = @_;
    my $app_instance = $c->app_instance;

    my $source = $app_instance->skin
        ? ($app_instance->skin->{sitemap} || $app_instance->config->{sitemap})
        : $app_instance->config->{sitemap};

    if ($source) {

        $source->{default_locale} ||= $c->config->{default_locale} || 'pt';
        K1Plaza::Sitemap->from_source($source, $c);
    }
    else {

        my $pages_dir = $app_instance->path_to('template/page');
        return unless -d $pages_dir;
        K1Plaza::Sitemap->from_dir($pages_dir, $c);
    }
}



1;
