#!/usr/bin/env perl
#
#  AUTHOR: cafe
#  DATE: Nov 9, 2012 
#  ABSTRACT: abstract

use utf8;
use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib 'lib';
use lib 't/lib';
use Q1::Web::Template::Plift;
use Devel::Cycle;
use Mojo::DOM;
use Path::Class qw/dir/;
use Devel::Refcount qw( refcount );
use Scalar::Util qw/ weaken isweak /;
use Devel::Monitor qw(:all);

#my $dom = Mojo::DOM->new->parse('<div><h1>A</h1></div>')->at('h1')->replace('<h2>B</h2>');
#warn $dom;

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/filter/"],
    enable_profiler => 1,    
    filters => ['StaticFiles']
);

#$plift->add_filter('StaticFiles', { });


system 'clear';
my $dom = $plift->process('1');

print $dom->as_html;




