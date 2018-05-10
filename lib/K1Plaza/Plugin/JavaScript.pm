package K1Plaza::Plugin::JavaScript;

use Mojo::Base 'Mojolicious::Plugin';
use Data::Printer;
use Mojo::Util qw/steady_time /;
use JavaScript::V8::CommonJS;
use Q1::Web::Template::Plift::jQuery;


sub register {
    my ($self, $app, $config) = @_;

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
    my $log = $c->log;
    my $app_instance = $c->app_instance;

    my $context_id = $app_instance
        ? $app_instance->id.($app_instance->deployment_version || '')
        : 'system';

    # reuse
    if ($pool{$context_id}) {
        $pool{$context_id}{total}++;
        $pool{$context_id}{last} = time;
        $log->debug("Reusing javascript context '$context_id' ($pool{$context_id}{total})");
        return $pool{$context_id}{context};
    }

    # new
    $pool{$context_id} = {
        last => time,
        total => 1,
        context => JavaScript::V8::CommonJS->new
    };

    # garbade collect
    my $task_id; $task_id = Mojo::IOLoop->recurring(60 => sub {
        my $loop = shift;
        unless ($pool{$context_id}) {
            $log->debug("JavaScript context '$context_id' is gone, exiting GC task.");
            $loop->remove($task_id);
            return;
        }

        my $finished = 0;
        my $time = steady_time;
        my $js = $pool{$context_id}{context}->c;
        while (not $finished) {
            $finished = $js->idle_notification;
        }

        $log->debug(sprintf "JavaScript GC done. (%.03f s)",  steady_time - $time);
    });

    # our require.js
    my $require_js = $c->app->home->child('share/system/require.js');
    if (-f $require_js) {
        $pool{$context_id}{context}->eval($require_js->slurp, "$require_js");
    }

    # native modules
    $pool{$context_id}{context}->add_module('k1/jquery', sub { j(@_) });

    # return
    $pool{$context_id}{context};
}




1;
