#!/usr/bin/env perl

use Test::More;
use strict;
use FindBin;
use lib 'lib';
use Data::Dumper;
use JavaScript::V8::CommonJS;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/filter/"],
    environment => 'development',
    filters => ['Console'],
    javascript_context => JavaScript::V8::CommonJS->new( time_limit => 5 )
);

$plift->context->{console} = [
    [ 'log', 'foo', 10, { bar => 'baz' } ],
    [ 'error', 'some error' ],
];

my $el = $plift->process('console');
# diag $el->as_html;
is $el->find('script')->text, 'console.log("foo", "10", {"bar":"baz"}); console.error("some error"); console.log("foobar"); ';

done_testing;
