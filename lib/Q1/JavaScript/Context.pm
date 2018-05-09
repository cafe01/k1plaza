package Q1::JavaScript::Context;

use Data::Printer;
use Moo;
use namespace::autoclean;
use JavaScript::V8;
use Try::Tiny;
use Class::Load;


has 'time_limit', is => 'ro', default => 5;

has '_ctx', is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    JavaScript::V8::Context->new( time_limit => $self->time_limit );
};

has 'debug', is => 'ro', default => $ENV{DEBUG_JAVASCRIPT_CONTEXT};

has 'wrapper_vars', is => 'rw', clearer => 'clear_wrapper_vars';

sub eval {
    my ($self, $src, $origin) = @_;

    $origin //= '<inline>';

    if ($self->debug) {
        Class::Load::load_class('JavaScript::Beautifier');
        printf STDERR "[%s] evaluating javascript code '%s':\n%s\n\n",
            scalar localtime,
            $origin,
            JavaScript::Beautifier::js_beautify($src);
    }

    my $rv =  $self->_ctx->eval($src, $origin);

    unless (defined $rv) {
        die "[JS eval error] $@";
        # Q1::JavaScript::Exception->throw({
        #     message => $@,
        #     source => $src
        # });
    }

    # if (ref $rv eq 'CODE') {
    #     my $code = $rv;
    #     $rv = sub {
    #         my @args = @_;
    #         $code->(@args)
    #         # try { $code->(@args) }
    #         # catch {
    #         #     die $_ if $_ =~ /at .* line \d+\./;
    #         #     warn "[JS code Exception] $_";
    #         #     Q1::JavaScript::Exception->throw({
    #         #         message => $_,
    #         #         source => $src
    #         #     });
    #         # };
    #     };
    # }

    $rv;
}


sub eval_wrapped {
    my ($self, $code, $origin, $vars) = @_;

    $origin ||= '<inline>';
    $vars //= {};
    # $vars = { %$vars, %{ $self->wrapper_vars || {} } };

    my $wrapper = $self->create_wrapper($code, $origin, [keys %$vars]);
    my $rv = $wrapper->(values %$vars);
}

sub create_wrapper {
    my ($self, $code, $origin, $vars) = @_;
    $origin ||= '<inline>';

    my $wrapper_src = sprintf "(function(%s){ \"use strict\"; return (function(){ %s }).call(''); })", join(', ', @{$vars||[]}), $code;
    # my @extra_vars;
    # push @extra_vars, sort keys %{$self->wrapper_vars}
    #     if $self->wrapper_vars;

    # my $wrapper_src = sprintf "(function(%s){ \"use strict\";  %s; })",
    #     join(', ', @{ $vars || [] }),
    #     $code;

    my $wrapper = $self->eval($wrapper_src, $origin);

    # if ($self->wrapper_vars) {
    #
    #     my $inner = $wrapper;
    #     my $vars = $self->wrapper_vars;
    #     my @extra_args = map { $vars->{$_} } @extra_vars;
    #
    #     $wrapper = sub {
    #         my @args = (@_, @extra_args);
    #         my $rv = $inner->(@args);
    #     }
    # }

    $wrapper;
}


sub cleanup {
    my $self = shift;
    $self->clear_wrapper_vars;
    my $ctx = $self->_ctx;
    my $done = 0;
    until ($done) {
        $done = $ctx->idle_notification;
    }
}




1;
