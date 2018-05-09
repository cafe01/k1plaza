package K1Plaza;

use Mojo::Base 'Mojolicious';
use Mojo::Home;
use FindBin;
use Cwd qw/ getcwd /;
use Q1::Utils::Properties;
use K1Plaza::Schema;
use YAML::Any;
use Mojo::Util 'getopt';
use Mojo::URL;
use Mojo::Loader qw/ load_class /;
use Hash::Merge qw/ merge /;
use Data::Printer;
use feature 'current_sub';

has home => sub {
    my $path = $ENV{K1PLAZA_HOME} || getcwd;
    return Mojo::Home->new(File::Spec->rel2abs($path));
};


has schema => sub {
    my $self = shift;
    my $config = $self->config;

    my $schema = K1Plaza::Schema->connect("dbi:mysql:dbname=$config->{db_name};host=$config->{db_host};port=$config->{db_port}", $config->{db_username}, $config->{db_password}, $config->{db_options})
        or die "Could not connect to database. (dbname=$config->{db_name};host=$config->{db_host};port=$config->{db_port};user=$config->{db_username});password=".($config->{db_password} =~ s/./*/gr);

    $schema;
};


# startup
sub startup {
    my $self = shift;

    my $config = $self->load_config;
    my $schema = $self->schema;

    # log level & format
    my $log = $self->log;
    $log->level($config->{log_level} || 'info');

    if ($self->mode eq 'development') {
        $log->short(1);
        $log->format(sub { shift; "[" . shift() . "] " . join "\n", @_, '' });
    }

    # safe deploy
    Mojo::IOLoop->next_tick(sub { $schema->safe_deploy($log) });

    # parse cmd line
    my %opt;
    $opt{dev} = $ENV{K1PLAZA_DEVELOPER} if defined $ENV{K1PLAZA_DEVELOPER};
    getopt \@ARGV,
        'dev' => \$opt{dev};

    # use commands from our namespace
    push @{$self->commands->namespaces}, 'K1Plaza::Command';
    $self->static->paths([$self->home->child('share/system/static/')->to_abs->to_string]);
    $self->renderer->paths([$self->home->child('share/system/template/')->to_abs->to_string]);

    # sessions
    $self->sessions->cookie_name('k1plaza');

    # config ua
    $self->ua->max_redirects(3);

    # build routes before loading AppInstances plugin
    $self->_setup_routes;

    # helpers
    $self->_setup_helpers;

    # exception mail alert
    $self->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        eval { $next->() };
        if (my $e = $@) {
            $c->send_system_alert_email("K1Plaza error", $e);
            die $e;
        }
    }) if $self->mode eq 'production';

    # rewrite rule for /.static
    $self->hook(before_dispatch => sub {
        my ($c) = @_;
        my $req = $c->req;
        my $url = $req->url;

        return unless $req->method eq 'GET' && $url->path =~ m|^/\.static|;
        $url->path($url->path =~ s!/\.static!!r);
    });

    $self->hook(after_static => sub {

        # remove cookies for static files
        my $c = shift;
        $c->res->headers->remove('Set-Cookie');

        # add CORS header for cdn host
        if ($c->is_cdn_host) {

            my $url = Mojo::URL->new("http://".$c->app_instance->current_alias);
            $url->port($c->req->url->base->port);
            $c->res->headers->access_control_allow_origin('*');
        }

        # TODO do not router-dispatch on cdn host
    });

    # plugins
    $self->plugin("Facets",
        $config->{backoffice_host} ? (
        backoffice => {
            host  => $config->{backoffice_host},
            setup => \&_setup_backoffice
        },
        ) : (),
        $opt{dev} ? (
        developer => {
            path  => '/.dev',
            setup => \&_setup_developer
        }
        ) : ()
    );

    $self->plugin(CHI => {
        default => {
            driver => 'Null',
            %{ $config->{cache} || {} }
        }
    });

    $self->plugin('K1Plaza::Plugin::Apis');
    $self->plugin('K1Plaza::Plugin::AppInstances');
    $self->plugin('K1Plaza::Plugin::Plift');
    $self->plugin('K1Plaza::Plugin::Widgets');
    $self->plugin('K1Plaza::Plugin::Forms');
    $self->plugin('K1Plaza::Plugin::Users');
    $self->plugin('K1Plaza::Plugin::Medias');
    $self->plugin('K1Plaza::Plugin::ImageScale');
    $self->plugin('K1Plaza::Plugin::Sitemap'); # must be last


    $log->info("K1Plaza started in ".$self->mode." mode.");
}


sub _setup_helpers {
    my $self = shift;

    $self->helper(log => sub { shift->app->log });
    $self->helper(cache => sub { shift->chi });

    $self->helper(uri_for => sub {
        my ($c, $path, $args, $query, $options) = @_;
        my $url = Mojo::URL->new($path)->to_abs($c->req->url->base);
        push @{$url->path}, @$args if $args;
        $url->query(%{ $query || {} });
        $url;
    });

    $self->helper(uri_for_static => sub {
        my ($c, $path, $opt) = @_;
        $path =~ s!^\/!!;
        my $url = Mojo::URL->new($path);

        my $base = $c->has_app_instance && $c->app->config->{cdn_host}
            ? Mojo::URL->new(sprintf 'http://%s/%s/', $c->app->config->{cdn_host}, $c->app_instance->current_alias)
            : $c->req->url->base;

        $base->port($c->req->url->base->port);
        $url->to_abs($base);
    });

    $self->helper( properties => sub {
        my $c = shift;
        $c->stash->{'k1plaza.properties'} //= Q1::Utils::Properties->new;
        $c->stash->{'k1plaza.properties'};
    });

    # locale
    $self->helper( locale => sub {
        my $c = shift;

        my $locale = $c->captures->{locale}
        || ( $c->has_app_instance ? $c->app_instance->config->{default_locale} ||
                                    $c->app_instance->config->{$c->app_instance->current_alias}->{default_locale}
                                  : undef )
        || $c->app->config->{default_locale};

        $c->properties->set("locale.$locale");
        $c->stash->{locale} = $locale
    });
}


sub _setup_routes {
    my $self = shift;

    $self->plugin('K1Plaza::Plugin::Shortcuts');

    my $r = $self->routes;

    # login
    $r->get('/.login' => { handler => 'plift' })->to('login#do_login')->name('login');
    $r->get('/.logout')->to('login#do_logout')->name('logout');

    # authenticated
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

    # media controller
    my $media = $admin->resource('media', prefix => '/.media');
    $media->post('/reposition')->to("#reposition")->name('reposition_media');
    $r->get('/.media/file/#file_path')->to("resource-media#download")->name('download_media');

    # user & role
    my $user = $admin->resource('user');

    my $role = $admin->resource('role');
    $role->get('/:id/members')->to('#list_members');
    $role->put('/:id/members')->to('#add_members');
    $role->delete('/:id/members/:member_ids')->to('#remove_members');

    # blog
    my $blog = $admin->resource('blog', prefix => '/.resource/blog/:blog_name');

    # expo
    $admin->resource('expo', prefix => '/.resource/expo/:expo_name')
          ->post('/reposition')->to("#reposition")->name('reposition_expo');

    # sitemap
    $admin->resource('sitemap');

    # content
    $admin->post('/.content/save')->to('content#save');

    # widget
    my $widget = $admin->any('/.widget/:widget_name')->to('widget#')->name('widget');
    $widget->get('/')->to('#list')->name('list_widget');
    $widget->get('/:id')->to('#list_single')->name('list_single_widget');
    $widget->put('/:id')->to('#update')->name('update_widget');
    $widget->delete('/:id')->to('#remove')->name('remove_widget');
    $widget->post('/:widget_action' => { widget_action => 'create_resource'})
           ->to('#widget_action')->name('widget_action');

    # DBIC resource proxy
    my $resource_proxy = $admin->resource('resource',
        prefix => '/.resource/:resource_name',
        controller => 'resource-proxy');

}


sub _setup_backoffice {
    my $app = shift;

    my $routes = $app->routes;
    my $r = $routes->under([format => 0])->to('login#access_check');

    @{$app->routes->namespaces} = qw/ K1Plaza::Backoffice /;
    unshift @{$app->static->paths},   $app->home->child('share/backoffice/static')->to_string;
    unshift @{$app->renderer->paths}, $app->home->child('share/backoffice/template')->to_string;

    $app->plugin('K1Plaza::Plugin::Minion', route => $r->any('/minion'));
    $app->plugin('K1Plaza::Plugin::Shortcuts');

    $routes->get('/.login')->to("login#do_login")->name('login');
    $routes->get('/.logout')->to("login#do_logout")->name('logout');

    $routes->post('/api-apps/github_webhook')->to("resource-apps#github_webhook");
    $routes->post('/.github_webhook')->to("resource-apps#github_webhook");

    $r->get('/' => { template => 'apps', handler => 'plift' });
    $r->get('/app/:appid' => { template => 'apps.single', handler => 'plift' });

    $r->resource('apps')
      ->post('/deploy_repository')->to('#deploy_repository');

    $r->resource('user');
    $r->resource('hostname');
}


sub _setup_developer {
    my $app = shift;

    die 'Missing "developer_workspace" config.' unless $app->config->{developer_workspace};

    $app->plugin('K1Plaza::Plugin::Shortcuts');

    my $routes = $app->routes;
    my $r = $routes->under([format => 0 ]);

    $app->sessions->cookie_name('k1developer');
    @{$app->routes->namespaces} = qw/ K1Plaza::Developer /;
    unshift @{$app->static->paths},   $app->home->child('share/developer/static')->to_string;
    unshift @{$app->renderer->paths}, $app->home->child('share/developer/template')->to_string;

    $r->get('/' => { template => 'index', handler => 'plift' });
    $r->get('/config' => { template => 'config', handler => 'plift' })->name('developer-settings');
    $r->resource('project')
      ->post('select')->to('#select_project');

    $r->resource('settings')
      ->post('/token')->to('#update_token');

    my $database_connected = 0;
    Mojo::IOLoop->timer(1, sub {
        $database_connected = $app->schema->storage->connected;
        shift->timer(1, __SUB__) unless $database_connected;
    });


    # get/set developer settings
    $app->helper(developer_settings => sub {
        my $c = shift;
        my $api = $c->api('Data', { app_instance_id => -1 });
        return $api->set('developer_settings', $_[0]) if $_[0];
        my $settings = $api->get('developer_settings') || {};
        $settings->{initial_setup} = $settings->{github_access_token} ? 0 : 1;
        $settings;
    });

    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;

        # database not connected
        return $c->render(text => "Sem conexão com o banco de dados. Se você acabou de iniciar o ambiente, aguarde alguns segundos para o mysql iniciar e atualize a pagina.  Se o erro persistir, confira seu setup! :)")
            unless $database_connected;

        $next->();
    })
}






sub load_config {

    my $app = shift;
    $app->plugin( Config => {
        file    => $app->home->child('k1plaza.conf')->to_string,
        default => {
            secrets => [],
            default_locale => 'pt',
            developer_workspace => '/projects',

            db_host => 'db',
            db_port => 3306,
            db_name => 'k1plaza_'.$app->mode,
            db_username => 'k1plaza',
            db_password => 'P@ssw0rd',
            db_options => { mysql_enable_utf8 => 1, quote_names => 1 },

            system_alert_email_recipient => undef,

            auth_host => undef,
            cdn_host => undef,
            backoffice_host => 'backoffice',

            amazon_s3_use_cname => 1,
            amazon_s3_bucket => undef,
            media_storage_type => 'fs',

            resources => {
                # user => { class => 'User' },
                data => { api_class => 'Data', class => 'DBIC' },
                category => { api_class => 'Category', class => 'DBIC' },
                tag => { api_class => 'Tag', external_id_field => 'slug', class => 'DBIC'  }
            },

            smtp => {
                host => 'smtp.mailtrap.io',
                port => 2525,
                ssl => 0,
                username => '',
                password => '',
            },

            unsplash => {
                access_key => '89b60954b118e828c81eadf93e4a8685646ffb84e59784c9dc9876c2565b8ac5'
            },

            instagram => {
                # Instagram App: K1Plaza Developer
                client_id => '201d5785f80348bd9c456080c25d1335',
                client_secret => 'afb81f19afac42aaa82637abee109203'
            },

            google => {
                # Google Project: K1Plaza Developer
                api_key => 'AIzaSyB6jhFZYm-3VKwrSalJgQk1uZBebn6y508',
                client_id => undef,
                client_secret => undef,
            },

            facebook => {
                app_id => undef,
                app_secret => undef,
            },

            aws => {
                s3_access_id => undef,
                s3_secret_key => undef
            },

            cloudflare => {
                api_user => undef,
                api_key => undef
            },

            git => {
                ssh_private_key => "/home/k1plaza/.ssh/id_rsa",
                ssh_public_key => "/home/k1plaza/.ssh/id_rsa.pub"
            },

            hypnotoad => {
                accepts => 1000,
                clients => 100,
                workers => 2,
                proxy => 1,
                pid_file => '/home/k1plaza/k1plaza_hypnotoad.pid',
                listen => ['http://*:3000']
            },
        },
    });

    if ( my $secrets = $app->config->{secrets} ) {
        $app->secrets($secrets) if @$secrets;
    }

    $app->config;
}


# shim attributes/methods
has _debug_skin => sub { $ENV{DEBUG_SKIN} };

sub environment { shift->mode }

sub path_to {
    shift->home->child(@_)
}

sub loadConfigFile { YAML::Any::LoadFile($_[1]) }

sub load_merged_config_files {
	my ($self, @files) = @_;
	my $result = {};
	foreach (reverse @files) {
	    my $config = $self->loadConfigFile($_);
	    $result = merge($config, $result);
	}
	$result;
}

1;
