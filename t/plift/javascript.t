#!/usr/bin/env perl
use Test::More;
use Test::Exception;
use strict;
use FindBin;
use lib 'lib';
use lib 't/lib';
use Data::Dumper;
#use Cwd;
use Path::Tiny;
use utf8;
use JavaScript::V8::CommonJS;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/javascript/"],
    javascript_include_path => [path($FindBin::Bin ."/templates/javascript/")],
    enable_profiler => 0,
    debug => 1,
    filters => [],
    javascript_context => JavaScript::V8::CommonJS->new
);



is scalar $plift->process('page')->as_html, "<div><h1>Hello Javascript!</h1></div>\n", 'javascript snippet';
is scalar $plift->process('xtag')->as_html, "<h1>Hello Javascript!</h1>\n", 'javascript snippet via xtag';
is scalar $plift->process('snippet-params')->as_html, "<div>Params are cool!</div>\nworks with x-tags\n", 'javascript snippet params';

is $plift->process('script')->find('h1 + h2 + h3')->text, "baz", 'inline script';

done_testing;
