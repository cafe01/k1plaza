#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Q1::Web::Template::Plift;
use CHI;

use feature 'say';

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/html/"],
    enable_profiler => 1,
    cache => CHI->new( driver => 'Null', datastore => {} )
);



run_include();
run_include();


sub run_include {
    say $plift->process('include')->as_html;
    say scalar $plift->profiler->report;    
    $plift->reset_profiler;
}
