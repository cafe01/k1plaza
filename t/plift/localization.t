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
    include_path => [$FindBin::Bin ."/templates/localization/"],
    enable_profiler => 1,   
    locale => 'en_US' 
);


like scalar $plift->process('default')->as_html, qr{default}, 'rendered default.html';

like scalar $plift->process('language')->as_html, qr{colour}, 'rendered language_en.html';

like scalar $plift->process('territory')->as_html, qr{color}, 'rendered territory_enUS.html';

