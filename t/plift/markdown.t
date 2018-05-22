#!/usr/bin/env perl
use Test::More;
use strict;
use FindBin;
use Data::Dumper;
use Q1::Web::Template::Plift;


my $plift = Q1::Web::Template::Plift->new( 
    include_path => ["$FindBin::Bin/templates/"]
);


like $plift->process('markdown')->as_html, qr(<h1>hello markdown</h1>), 'markdown';



done_testing;