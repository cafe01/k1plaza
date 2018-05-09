package K1Plaza::Plugin::Plift;

use Mojo::Base 'Mojolicious::Plugin';
use Q1::Web::Template::Plift;
use Mojo::Util qw/decode steady_time /;
use Scalar::Util qw/ weaken /;
use Data::Printer;
use Mojo::File qw/ path /;
use Q1::JavaScript::Context;

__PACKAGE__->attr([qw/ plift config /]);

my $GCID;

sub register {
    my ( $self, $app, $config ) = @_;

    $self->config($config || {});
    my $plift = $self->_build_plift($config);
    $self->plift($plift);

    $GCID = Mojo::IOLoop->recurring(120 => sub {
        my $loop = shift;
        my $time = steady_time;
        my $js = $plift->javascript_context;
        my $finished = 0;
        while (not $finished) {
            $finished = $js->_ctx->idle_notification;
        }
        my $took = steady_time - $time;
        # $app->log->debug("JS Garbage collected. ($took s)");
    });

    $app->helper( plift => sub { $plift });

    $app->helper( find_template_file => sub {
        my $c = shift;
        return unless $_[0]; # allow no args call to vivify helper
        local $plift->{include_path} = $app->renderer->paths;
        $plift->find_template_file($_[0]);
    });

    $app->helper( template_include_path => sub {
        return shift->app->renderer->paths
    });

    $app->renderer->add_handler(
        plift => sub { $self->_render(@_) }
    );
}


sub _render {
    my ( $self, $renderer, $c, $output, $options ) = @_;

    my $template = $options->{template};
    return unless defined $template;
    return if ref $template && !defined $$template;

    # vars
    my $tx = $c;
    my $app = $tx->app;
    my $app_env = $app->mode;
    my $app_class = ref $app;
    my $app_instance = $tx->has_app_instance ? $tx->app_instance : undef;

    # setup plift
    my $plift = $self->plift;
    my $stash = $c->stash;

    # include path
    local $plift->{include_path} = $renderer->paths;

    # static_path
    local $plift->{static_path} = $app->static->paths;

    # snippet
    local $plift->{javascript_include_path} = [map { path($_)->sibling('snippet')->to_string } @{$plift->static_path}];

    # sass private paths
    $stash->{_sass_private_paths} = [$app->home->to_string];

    # _sass_no_compile flag
    $stash->{_sass_no_compile} = $app_env ne 'development';

    # properties
    $plift->properties($tx->properties);

    # env
    $plift->environment($app_instance ? $app_instance->environment : $app_env);

    # context
    $plift->context($stash);

    # tx ref
    $stash->{tx} = $tx;
    weaken $stash->{tx};

    # locale
    $self->plift->locale($tx->locale);

    # set profiler
    # $self->plift->profiler($tx->stats) if $tx->stats;

    # process
    my $document = $plift->process($template);

    # pass the rendered result back to the renderer
    $$output = defined $c->res->body && length $c->res->body
        ? $c->res->body
        : decode 'UTF-8', $document->as_html;
}


sub _build_plift {
    my $self = shift;
    my $cfg = $self->config;

    my $plift = Q1::Web::Template::Plift->new(
        filters         => [qw/ EditableContent AppendJavascript CurrentPage OpenGraph AnalyticsMetaTags StaticFiles Truncate LeakCheck Console /],
        enable_profiler => $cfg->{debug},
        debug           => $cfg->{debug},
        snippet_path    => ["K1Plaza::Snippet"],
        javascript_context => Q1::JavaScript::Context->new
    );

    $plift;
}


sub DESTROY {
    Mojo::IOLoop->remove($GCID);
}

1;
