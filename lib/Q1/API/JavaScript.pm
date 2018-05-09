package Q1::API::JavaScript;

use Moo;
# use namespace::autoclean;
use Q1::JavaScript::Context;
use Data::Dumper;

use feature qw(signatures);
no warnings qw(experimental::signatures);

has 'tx', is => 'rw';

has '_context_cache' =>  (
    is => 'ro',
    init_args => undef,
    default => sub { {} }
);


my $js_ctx_time_token = 0;

sub get_context ($self) {

    my $tx = $self->tx;
    unless ($tx->has_app_instance) {
        my $ctx = Q1::JavaScript::Context->new( time_limit => 5 );
        # $ctx->wrapper_vars({ tx => $tx });
        return $ctx;
    }

    my $app_instance = $tx->app_instance;
    my $ctx_cache = $self->_context_cache;
    my $cached = $ctx_cache->{$app_instance->id};

    if ($cached) {
        $cached->{time_token} = ++$js_ctx_time_token;
    }
    else {
        my $max_ctx = $tx->app->config->{max_javascript_context} || 3;

        # if cached size exceded, delete the least used item
        if (scalar(keys %$ctx_cache) >= $max_ctx) {
            my $id_to_delete;
            my $current_min;
            foreach my $app_id (keys %$ctx_cache) {
                my $time_token = $ctx_cache->{$app_id}->{time_token};
                $id_to_delete //= $app_id;
                $current_min //= $app_id;

            }
        }

        # $cached = {
        #     ctx => Q1::JavaScript::Context->new( time_limit => 5 ),
        #     time_token => ++$js_ctx_time_token
        # };
        $cached = $ctx_cache->{$app_instance->id} = {
            ctx => Q1::JavaScript::Context->new( time_limit => 5 ),
            time_token => ++$js_ctx_time_token
        };

        # init js context
        $tx->app->init_javascript_context($cached->{ctx})
            if $tx->app->can('init_javascript_context');
    }

    # set tx env flag
    $tx->env->{'q1.has_javascript_context'} = 1
        if $tx->can('env');

    # $cached->{ctx}->wrapper_vars({ tx => $tx, app => $app_instance });
    $cached->{ctx};
}

sub eval ($self, $code, $origin = "<inline>", $vars = {}) {

    $self->get_context->eval_wrapped($code, $origin, $vars);
}


sub eval_file ($self, $file, $vars = undef) {

    my $app_instance = $self->tx->app_instance;
    $file = $self->tx->app_instance->path_to($file)
        unless ref $file;

    $self->eval($file->slurp, $file->relative($app_instance->base_dir), $vars);
}




1;
