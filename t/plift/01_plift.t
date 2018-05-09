#!/usr/bin/env perl
use Test::More 'no_plan';
use strict;
use FindBin;
use lib 'lib';
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new( include_path => ["$FindBin::Bin/templates/"], snippet_path => ['Snippet'] );

# no plift tags left
unlike $plift->process('page1')->as_html, qr(data-plift), 'no plift tags left';

# full document
subtest 'full document' => sub {
    my $doc = $plift->process('page1');
    # diag $doc->as_html;
    is $doc->find('head > title')->text, 'title to layout';
    is $doc->find('body.layout > #content > #main > p > b')->text, 'loren ipsin!!!';
    is $doc->find('body.layout > footer')->text, 'Footer!';
};
# my $expected_fulldoc = qr{^<!DOCTYPE html>\s*<html>\s*<head><title>title to layout</title></head>\s*<body class="layout">\s*<div><header>Header!</header></div>\s*<div id="content">\s*<div id="main" class="">\s*conte&uacute;do da pagina 1\s*<p><b>loren ipsin!!!</b></p>\s*</div>\s*</div>\s*<footer>Footer!</footer>\s*</body>\s*</html>\s*$};

# environment
$plift->environment('dev');
like $plift->process('environment')->as_html, qr!\s+<div>dev</div>\s+<div>ok</div>\s+!, 'environment bound elements';

# nesting: runs from outer to inner
is $plift->process('nesting')->find('foo > bar > baz')->text, "ok", 'nesting: runs from outer to inner';

# run_snippet
is $plift->process('run_snippet')->find('div > b')->text, "loren ipsin!!!", 'run_snippet';


BEGIN {
    package Snippet::outer;
    use Moo;

    sub process {
        my ($self, $el) = @_;
        $el->find('bar')->append('<baz/>');
    }

    package Snippet::inner;
    use Moo;

    sub process {
        my ($self, $el) = @_;
        $el->find('baz')->text('ok');
    }

    package Snippet::run_snippet;
    use Moo;

    sub process {
        my ($self, $el, $engine) = @_;
        $engine->run_snippet('include', $el, { name => 'loren' });
    }
}
