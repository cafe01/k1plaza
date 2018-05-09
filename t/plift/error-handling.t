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

BEGIN { 
    use_ok 'Q1::Web::Template::Plift';   
}

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/"]
);

# dies on unknown template
dies_ok { $plift->process('unknown_template') } 'dies on unknown template';

# dies on invalid 'data-plift-template'
dies_ok { $plift->process('invalid-page1') } "dies on invalid 'data-plift-template'";

# dies on invalid snippet name
dies_ok { $plift->process('invalid-snippet-name') } "dies on invalid snippet name";

# process
#diag $plift->process('page1');




