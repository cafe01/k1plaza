#!/usr/bin/env perl

use Test::More 'no_plan';
use strict;
use FindBin;
use lib 'lib';
use lib 't/lib';
use lib $FindBin::Bin ."/lib";
use Data::Dumper;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new(
    include_path    => [$FindBin::Bin ."/templates/filter/"],
    snippet_path    => ['Snippet'],
    enable_profiler => 1,
    filters         => ['AppendJavascript']
);



my $result = $plift->process('append_javascript')->as_html;
my $expected = quotemeta '<script type="text/javascript">jscode</script></body>';
like $result, qr{<script type="text/javascript">jscode</script>\s*</body>}, 'injected before body close';
