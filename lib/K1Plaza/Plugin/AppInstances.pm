package K1Plaza::Plugin::AppInstances;

use Mojo::Base 'Mojolicious::Plugin';
use Q1::API::Skin;
use Data::Printer;

my @DEFAULT_STATIC_PATHS;
my @DEFAULT_RENDERER_PATHS;

sub register {
    my ($self, $app) = @_;

    # save default static paths
    @DEFAULT_STATIC_PATHS = @{$app->static->paths};
    @DEFAULT_RENDERER_PATHS = @{$app->renderer->paths};

    # helper: skin_manager
    my $skin_manager = Q1::API::Skin->new( app => $app );
    $app->helper(skin_manager => sub { $skin_manager });

    # helpers
    $app->helper( app_instance => sub { shift->stash->{'__app_instance'} });
    $app->helper( has_app_instance => sub { defined shift->stash->{'__app_instance'} });

    $app->helper( is_cdn_host => \&_is_cdn_host);
    $app->helper( is_auth_host => \&_is_auth_host);

    # hook
    $app->hook(around_dispatch => \&_around_dispatch);

    # website sitemap root
    $app->routes->any
        ->to("render_page#default")
        ->name('website');

    $app->add_facet(backend => {
        path  => '/.backend',
        setup => \&_setup_backend
    });

}

sub _setup_backend {
    my $app = shift;

    unshift @{$app->static->paths},   map { $app->home->child("share/$_/static")->to_string }   qw( backend system );
    unshift @{$app->renderer->paths}, map { $app->home->child("share/$_/template")->to_string } qw( backend system );

    # share website session
    $app->sessions->cookie_name('k1plaza');

    # routes
    my $r = $app->routes;

    $r->get('/.login' => { handler => 'plift' })->to('login#do_login')->name('login');
    $r->get('/.logout')->to('login#do_logout')->name('logout');

    my $admin = $r->under(sub {
        my $c = shift;
        if ($c->user_exists) {
            return $c->user->check_any_roles(qw/ instance_admin admin /)
                ? 1
                : $c->render(template => '403', handler => 'plift');
        }

        $c->rendered(403);
        $c->redirect_to_login( continue => 1 )
            if $c->req->method eq 'GET' && !$c->req->is_xhr;

        return;
    })->name('admin');

    $admin->get('/' => sub {
        my $c = shift;
        $c->render(
            template => 'backend-v2',
            handler => 'plift'
        );
    })->name('backend');
}

sub _around_dispatch {
    my ($next, $c) = @_;
    my $log = $c->app->log;
    my $static = $c->app->static;
    my $renderer = $c->app->renderer;

    # not if in another facet
    return $next->() if $c->stash->{'mojox.facet'} && $c->stash->{'mojox.facet'} ne 'backend';

    # developer session
    my $alias;
    if ($c->has_facet("developer")) {

        my $dev_session = $c->facet_do('developer', sub { shift->session });
        if (my $project = $dev_session->{project}) {

            $alias = $project->{canonical_alias};

            # automatic developer login
            unless (($c->is_authenticated && $c->session->{__user}{app_instance_id} == $project->{session_user}{app_instance_id}) || $c->developer_settings->{disable_autologin}) {
                $c->login($project->{session_user});
            }
        }
    }

    # resolve alias
    $alias //= $c->req->headers->host;
    $alias =~ s/:\d+$//;

    if ($c->is_auth_host) {
        $log->debug("AUTH host detected.");
        my $params = $c->req->query_params;
        $alias = $params->param('domain') || $params->param('state');
        unless ($alias) {
            $log->debug("Missing 'domain' or 'state' parameter for shared auth host!");
            $c->res->code(400);
            return $c->render(text => "Error: missing 'domain' or 'state' parameter.");
        }
    }
    elsif ($c->is_cdn_host) {
        # Move first part (alias) and slash from path to base path
        $alias = shift @{$c->req->url->path->leading_slash(0)};

        # discard legacy ".static" path
        shift @{$c->req->url->path->leading_slash(0)} if
            ($c->req->url->path->leading_slash(0)->[0] || '') eq '.static';

        return $c->reply->not_found unless defined $alias && length $alias;

        push @{$c->req->url->base->path->trailing_slash(1)}, $alias;
        # $log->debug("CDN host detected for alias '$alias', base url is now: ". $c->req->url->base);
    }

	# find app
    if (my $app_instance = $c->api('AppInstance')->instantiate_by_alias($alias)) {

        # set app instannce for this request
        $c->stash->{'__app_instance'} = $app_instance;

        # load skin
        my $skin_manager = $c->skin_manager;
        $skin_manager->load_skin($c);

        # set skin paths
        local $c->app->static->{paths} =
            [map { "$_" } @{ $skin_manager->generate_static_search_path($c) }, @{$c->app->static->{paths}}];

        local $c->app->renderer->{paths} =
            [map { "$_" } @{ $skin_manager->generate_template_include_path($c) }, @{$c->app->renderer->{paths}}];

        # commonjs paths
        local $c->js->{paths} = [$app_instance->base_dir->to_string];

        # add app name to log lines
        my $app_name = $app_instance->name;

        local $log->{format} = $log->short
            ? sub { shift; "[" . shift() . "] [$app_name] " . join "\n", @_, '' }
            : sub { '[' . localtime(shift) . "] [" . shift() . "] [$app_name] " . join "\n", @_, '' };

        # mount sitemap
        my $routes = $c->app->routes;
        my $website_route = $routes->find('website')
            or return $next->();

        my $sitemap = $c->sitemap;

        local $website_route->{children} = $sitemap->children;
        local $routes->cache->{max_keys} = 0;

        # proceed with dispatcher
        $next->();
    }
    else {
        $log->info("App instance '$alias' not found.");
        $c->res->code(404);
        $c->render(text => 'Website not registered.');
    }
}


sub _is_cdn_host {
    my ($c) = @_;

    $c->stash->{'k1plaza.is_cdn_host'} //= do {
        my $cfg = $c->app->config;
        my $host = $c->req->headers->host =~ s/:\d+$//r;
        $cfg->{cdn_host} && $cfg->{cdn_host} eq $host ? 1 : 0;
    };

    $c->stash->{'k1plaza.is_cdn_host'};
}

sub _is_auth_host {
    my ($c) = @_;
    $c->stash->{'k1plaza.is_auth_host'} //= do {
        my $cfg = $c->app->config;
        my $host = $c->req->headers->host =~ s/:\d+$//r;
        $cfg->{auth_host} && $cfg->{auth_host} eq $host ? 1 : 0;
    };

    $c->stash->{'k1plaza.is_auth_host'};
}









1;
