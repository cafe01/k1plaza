package Q1::Web::API::Analytics;

use Moo;
use namespace::autoclean;
use utf8;
use Carp qw/ carp /;
use JSON::XS;
use Data::Dumper;

has 'tx', is => 'ro', required => 1;


sub get_series {
    my ($self, $series, $from, $to, $resolution) = @_;
    $series = [$series] unless ref $series;
    $resolution ||= '1h';

    my $tx = $self->tx;
    my $app = $tx->app;
    my $config = $app->config->{analytics};
    my $metrics = $self->get_metrics;

    # expand targets
    my $namespace = $config->{namespace};
    $namespace //= $app->mode eq 'production' ? $app->normalized_app_name : $app->app_and_env_name;
    $namespace = "stats.counters.".$namespace;

    my $appid = $tx->app_instance->id;
    my @targets = map {
        $_ =~ s/{(namespace|ns)}/$namespace/g;
        $_ =~ s/{appid}/$appid/g;
        $_ =~ s/{resolution}/$resolution/g;
        $_
    } map {
        exists $metrics->{$_} ? $metrics->{$_}->{query}
                              : ()
    } @$series;

    unless (@targets) {
        $tx->log->error("[API::Analytics] returning empty response: no targets");
        return [];
    }

    $self->query_graphite(
        from => $from || '-24hours',
        to   => $to   || 'now',
        map { (target => $_) } @targets
    );

}

sub get_metrics {
    my ($self) = @_;

    my $tx = $self->tx;
    my $config = $tx->app->config->{analytics};

    my $system_metrics = $config->{metrics} || {};
    my $skin = $tx->app_instance->skin
        or return $system_metrics;

    my $skin_metrics = $skin->{analytics}->{metrics} || {};
    return {%$skin_metrics, %$system_metrics};
}


sub query_graphite {
    my $self = shift;
    my $tx = $self->tx;
    my $config = $tx->app->config->{analytics};

    unless ($config->{graphite_host}) {
        $tx->log->error("[API::Analytics] returning empty response: missing 'graphite_host' config");
        return [];
    }

    # build url: http://graphite.q1software.com/render?from=-24hours&until=now&target=summarize(stats.counters.q1plaza.pageview.count, "10min")
    my $url = URI->new("http://$config->{graphite_host}/render");
    $url->query_form( @_, format => 'json' );

    my $res = $tx->ua->get($url);
    unless ($res->is_success) {
        $tx->log->error(sprintf "[API::Analytics] returning empty response: http error: (%d) %s", $res->code, $res->status_line);
        return [];
    }

    # decode
    decode_json $res->content;
}


1;
