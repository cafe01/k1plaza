#!/usr/bin/env perl
use Test::More;
use strict;
use FindBin;
use lib 'lib';
use lib 't/lib';
use lib $FindBin::Bin ."/lib";
use Data::Dumper;
use utf8;
use Q1::Web::Template::Plift;

my $plift = Q1::Web::Template::Plift->new(
    include_path => ["$FindBin::Bin/templates/"],
    filters => ['AnalyticsMetaTags']
);

# fixtures
$plift->context->{google_analytics_id} = 'UA-420';
$plift->context->{google_analytics_commands} = [
    [qw/ require pluginName /],
    [qw/ set dimension1 foo/]
];

# test
# diag $plift->process('google-analytics')->as_html;
like $plift->process('google-analytics')->as_html, qr!ga\("create","UA-420","auto"\);\s+
ga\("require","pluginName"\);\s+
ga\("set","dimension1","foo"\);\s+
ga\("send","pageview"\);!x, 'process';

# done
done_testing;
