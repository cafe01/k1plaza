#!/usr/bin/env perl

use Test::More;
use strict;
use FindBin;
use lib 'lib';
use Data::Dumper;
use DateTime;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/filter/"],
    filters => ['OpenGraph']
);

my $now = DateTime->now( time_zone => 'UTC' );

$plift->context->{opengraph} = {
    title => 'test: "quoted" title',
    article => {
        tag => [qw/ tag1 tag2 tag2 /],
        section => 'category',
        created_at => $now
    },
    foo => undef
};

my $el = $plift->process('opengraph');
# diag $el->as_html;

is $el->find('meta[property="og:type"]')->attr('content'), 'website', 'type';
is $el->find('meta[property="og:title"]')->attr('content'), $plift->context->{opengraph}{title}, 'title';
is $el->find('meta[property="article:tag"]')->size, 3, 'article:tag';
is $el->find('meta[property="article:section"]')->attr('content'), 'category', 'article:section';
is $el->find('meta[property="article:created_at"]')->attr('content'), $now->iso8601, 'article:created_at';

done_testing;
