package K1Plaza::Plugin::JavaScript;

use Mojo::Base 'Mojolicious::Plugin';
use Data::Printer;
use Mojo::Util qw/steady_time /;
use Mojo::Promise;
use JavaScript::V8::CommonJS;
use Q1::Web::Template::Plift::jQuery;
use Cwd qw/ getcwd /;
use K1Plaza::JS::Request;
use K1Plaza::JS::Flash;
use K1Plaza::JS::Stash;
use K1Plaza::JS::Console;
use K1Plaza::JS::Jobs;

my @system_module_paths = ( getcwd() . "/share/system/modules" );

sub register {
    my ($self, $app) = @_;

    $app->helper(js => sub {
        my $c = shift;

        unless ($c->stash->{'k1plaza.javascript'}) {
            $c->stash->{'k1plaza.javascript'} = $self->_build_context($c);
        }

        $c->stash->{'k1plaza.javascript'}
    });
}


my %pool;

sub _build_context {
    my ($self, $c) = @_;
    my $app = $c->app;
    my $log = $c->log;
    my $app_instance = $c->app_instance;

    my $context_id = $app_instance
        ? $app_instance->id.($app_instance->deployment_version || '')
        : 'system';


    # reuse js context
    my $js;
    if ($js = $pool{$context_id}) {

        $pool{$context_id}{total}++;
        $pool{$context_id}{last} = time;
        $log->debug("Reusing javascript context '$context_id' ($pool{$context_id}{total}) ".scalar(keys %pool));
        $js = $pool{$context_id};
    }
    else {
        # new js context

        $js = {
            last => time,
            total => 1,
            context => JavaScript::V8::CommonJS->new({
                paths => [@system_module_paths, $app_instance ? $app_instance->base_dir->to_string : ()],
                v8_params => {
                    time_limit => 5,
                    flags => '--use-strict --harmony-scoping --harmony-collections --max_old_space_size 200'
                }
            })
        };

        # cache for reuse
        my $use_js_pool = defined $app->config->{reuse_javascript_context}
            ? $app->config->{reuse_javascript_context}
            : $app->mode ne 'development';

        if ($use_js_pool) {

            # TODO delete contexts used many times

            # delete last used if full
            if (scalar keys %pool > 3) {

                my ($last_used_id) = sort {
                    $pool{$a}{last} <=> $pool{$b}{last}
                } keys %pool;

                $log->debug("[JS Pool] deleting context '$last_used_id'");
                delete $pool{$last_used_id};
            }

            $pool{$context_id} = $js;

            # garbade collect
            my $task_id; $task_id = Mojo::IOLoop->recurring(30 => sub {
                my $loop = shift;
                unless ($pool{$context_id}) {
                    $log->debug("JavaScript context '$context_id' is gone, exiting GC task.");
                    $loop->remove($task_id);
                    return;
                }

                my $time = steady_time;
                my $js = $pool{$context_id}{context}->c;
                until ($js->idle_notification) {}

                $log->debug(sprintf "JavaScript GC done. (%.03f s)",  steady_time - $time);
            });
        }

        # our require.js
        my $require_js = $c->app->home->child('share/system/require.js');
        if (-f $require_js) {
            $js->{context}->eval($require_js->slurp, "$require_js");
        }
    }

    # per-request context initialization

    # console
    $js->{context}->c->bind( console => K1Plaza::JS::Console->new($c) );

    my $modules = $js->{context}->modules;
    $modules->{'k1/jquery'} = sub { j(@_) };
    $modules->{'k1/ua'} = $c->ua;
    $modules->{'k1/promise'} = { new => sub { Mojo::Promise->new } };

    $modules->{'k1/csrf_token'} = $c->csrf_token;

    $modules->{'k1/jobs'} = K1Plaza::JS::Jobs->new($c);
    $modules->{'k1/request'} = K1Plaza::JS::Request->new($c->req);


    $modules->{'k1/cache'} = {

    };

    $modules->{'k1/session'} = {
        expires => sub {
            my $value = shift;
            return unless $value && $value =~ /^\d+$/;
            $c->session(expires => $value);
        },

        get => sub {
            my $key = shift or return;
            $c->session->{"$key"};
        },

        set => sub {
            my $key = shift or return;
            die "Session keys starting with __ are reserved for internal use."
                if $key =~ /^__/;
            $c->session->{"$key"} = shift;
        }
    };

    $modules->{'k1/flash'} = K1Plaza::JS::Flash->new($c);
    $modules->{'k1/stash'} = K1Plaza::JS::Stash->new($c);


    # return
    $js->{context};
}




1;
