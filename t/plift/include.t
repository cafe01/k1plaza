#!/usr/bin/env perl
use Test::More;
use strict;
use FindBin;
use lib $FindBin::Bin ."/lib";
use Data::Dumper;
use utf8;

#use Encode;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new( include_path => ["$FindBin::Bin/templates/"], snippet_path => ['Snippet']  );

# include
like $plift->process('layout')->as_html, qr(<div><header>Header!</header></div>), 'include';
like $plift->process('layout')->as_html, qr(<footer>Footer!</footer>\s*</body>), 'include - replace=1';

# included document has multiple root elements
is $plift->process('multiple')->as_html, "<div>foo</div>\n<div>bar</div>\n", 'include multiple';

# dont run if element is not part of document
is $plift->process('skip-detached')->find('div')->text, "content_replaced", 'skip detached';


done_testing;


BEGIN {
    package Snippet::skip_detached;
    use Moo;

    sub process {
        my ($self, $el) = @_;
        $el->text('content_replaced');
    }
}
