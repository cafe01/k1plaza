use strict;
use Test::More 0.98;
use FindBin;
use Q1::Web::Template::Plift;


my $plift = Q1::Web::Template::Plift->new(
    include_path => ["$FindBin::Bin/templates"]
);

my $dom = $plift->process('meta');

# use Data::Printer;
# p $plift->metadata;

is_deeply $plift->metadata, {
    title => 'the title',
    subtitle => 'new subtitle',
    foo => 'foo',
    bar => 'bar',
    baz => 'BAZ'
};

is $dom->document->find('x-meta')->size, 0;

done_testing;
