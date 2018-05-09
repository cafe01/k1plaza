package Test::K1Plaza;

use strict;
use warnings;
use v5.10;
use parent qw(Exporter);
use FindBin;

use Test2::V0;
use DBI;
use K1Plaza::Schema;
use Data::Printer;
use K1Plaza;

our @EXPORT = (
    @Test2::V0::EXPORT,
    # @Data::Printer::EXPORT,
    qw/
        p app
    /
);



sub import {
    my ($pkg) = @_;

    # modern perl
    $_->import for qw(strict warnings utf8);
    feature->import(':5.10');

    # our stuff, via Exporter::export_to_level
    $pkg->export_to_level(1, @_);
}


sub app {
    state $app;

    unless ($app) {
        $app = K1Plaza->new(
            home => Mojo::Home->new("t/test_home/")->to_abs
        );
        # $app->log->debug("Test app home: ".$app->home);

        $app->schema->deploy({ add_drop_table => 1 });
    }

    $app;
}


1;
