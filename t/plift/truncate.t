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
    include_path => [$FindBin::Bin ."/templates/filter/"],
    #enable_profiler => 1,    
    filters => ['Truncate']
);


# basic truncate
my $result = $plift->process('truncate')->as_html;

#diag $result;

is $result, '<div class="foobar">Sunt qu&aacute;s su...</div>'."\n", "truncate 15 caracteres";


# truncate with less content
$result = $plift->process('truncate2')->as_html;

#diag $result;

is $result, '<div class="foobar">Sunt q&uacute;</div>'."\n", "truncate with less content";


# testing die

dies_ok { $plift->process('truncate3') } 'Die: non-numeric value';