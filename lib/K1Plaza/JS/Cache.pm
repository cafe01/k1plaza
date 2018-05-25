package K1Plaza::JS::Cache;

use strict;
use warnings;
use Hash::Util::FieldHash 'fieldhash';
use Data::Printer;

fieldhash my %c;

sub new {
    my ($class, $mojo_c) = @_;
    die "called as instance method" if ref $class;
    my $self = bless \( my $object ), $class;
    $c{$self} = $mojo_c;
    return $self;
}


sub get {
    my ($self, $key) = @_;
    return unless $key;

    my $c = $c{$self};
    my $website = $c->app_instance;
    my $cache_ns = join ':', 'app', $website->id, $website->deployment_version || '';

    $c->chi->get("$cache_ns:$key");
}

sub set {
    my ($self, $key, $value, $time) = @_;
    return unless $key;

    my $c = $c{$self};
    my $website = $c->app_instance;
    my $cache_ns = join ':', 'app', $website->id, $website->deployment_version || '';

    $c->chi->set("$cache_ns:$key", $value, $time || '5m');
    $self;
}


1;
