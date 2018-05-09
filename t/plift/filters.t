#!/usr/bin/env perl

use Test::More 'no_plan';
use Test::Exception;
use strict;
use FindBin;
use lib 'lib';
use lib 't/lib';
use Data::Dumper;
use Cwd;
use Path::Class;
#use utf8;
#use Encode;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/filter/"]
);


my $without_filter = $plift->process('1')->as_html;

# basic filter
$plift->add_filter(sub{
    my ($doc) = @_;
    $doc->find("one")->append('<two/>');

});

my $doc = $plift->process('1');
##diag $doc->as_html;
is $doc->find('one > two')->size, 1;
is $doc->find('span#content + p')->size, 1;

# TODO: test call order
