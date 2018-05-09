#!/usr/bin/env perl
use Test::More 'no_plan';
use strict;
use FindBin;
use lib 'lib';
use lib 't/lib';
use lib $FindBin::Bin ."/lib";
use Data::Dumper;
use utf8;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new( snippet_path => ['Snippet'], include_path => ["$FindBin::Bin/templates/"] );

like $plift->process('page1')->as_html, qr(<div><header>Header!</header></div>), 'wrap';
like $plift->process('wrap-content')->as_html, qr(<div id="content">\s*<b>conte&uacute;do da pagina</b>\s*</div>), 'wrap - content=1';
like $plift->process('wrap-replace')->as_html, qr(</header></div>\s*<div id="main"), 'wrap - replace=1';

is $plift->process('wrap1')->find("span#content + p")->text, "222222", 'wrap - wrapper element is root and has sibling';

is $plift->process('wrap-process-order')->find('mine')->text, 'ok', 'process_order';



BEGIN {
    package Snippet::process_order;
    use Moo;

    sub process {
        my ($self, $el) = @_;
        $el->document->find('mine')->text('ok');
    }
}
