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
use DBI;

our @EXPORT = (
    @Test2::V0::EXPORT,
    # @Data::Printer::EXPORT,
    qw/
        p app js_test
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

        # create database
        my $dbh = DBI->connect("dbi:mysql:dbname=;host=db;port=3306", "root", 'P@ssw0rd', { mysql_enable_utf8 => 1, quote_names => 1, RaiseError => 1 } )
            or die "Could not connect to test database.";
    
        # $dbh->do("DROP DATABASE k1plaza_test IF EXISTS;");
        $dbh->do("CREATE DATABASE IF NOT EXISTS k1plaza_test;");
        $dbh->do("USE k1plaza_test;");            

        # app
        $app = K1Plaza->new(
            home => Mojo::Home->new("t/test_home/")->to_abs,
            mode => 'test',
            schema => K1Plaza::Schema->connect({ dbh_maker => sub { $dbh }})
        );

        my $js = $app->js;
        unshift @{$js->paths}, "$FindBin::Bin/test_modules";

        $js->c->bind( test => {
            is => sub { is shift, shift, shift },
            like => sub { like shift, shift, shift },
            ok => sub { ok  shift, shift },
            diag => sub { diag @_ },
        });

        # $app->schema->deploy({ add_drop_table => 1 });
    }

    $app;
}


sub js_test {
    my $test = shift;

    subtest $test => sub {
        eval {
            my $rv = app->build_controller->js->eval("require('test/$test')");
        };

        if ($@) {

            p $@->stack;
            die $@;
        }


    };
}

1;
