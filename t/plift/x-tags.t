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
use utf8;
#use Encode;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/xtags/"],
    enable_profiler => 0,
);

# x-include
subtest 'x-include' => sub {
    my $doc = $plift->process('layout');
    is $doc->find('body.layout > header')->text, 'Header!';
    is $doc->find('body.layout > footer')->text, 'Footer!';
};

# # x-wrap
subtest 'x-wrap' => sub {
    my $doc = $plift->process('page1');
    is $doc->find('body.layout > header')->text, 'Header!';
    is $doc->find('body.layout > footer')->text, 'Footer!';
    is $doc->find('body.layout > #content > b')->text, 'loren ipsin!!!';
};

# mixed x-tag and data-plift
subtest 'mixed x-tag and data-plift' => sub {
    my $doc = $plift->process('page2');
    is $doc->find('body.layout > header')->text, 'Header!';
    is $doc->find('body.layout > footer')->text, 'Footer!';
    is $doc->find('body.layout > #content > span > b')->text, 'loren ipsin!!!';
};
