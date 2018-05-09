#!/usr/bin/env perl
use Test::More;
use strict;
use FindBin;
use lib 'lib';
use lib 't/lib';
use lib $FindBin::Bin ."/lib";
use Data::Dumper;
use utf8;

#use Encode;

BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new(
    include_path => ["$FindBin::Bin/templates/"],
    locale => 'pt',
    environment => 'production'
);

$plift->properties->set(qw/ foo bar /);
my $doc = $plift->process('properties');


subtest 'default properties' => sub {
    is $doc->find('.environment')->size, 1, 'environment';
    is $doc->find('.locale')->size, 1, 'locale';
};

# remove-if
subtest 'remove if' => sub {
    is $doc->find('.remove-if-foo')->size, 0;
    is $doc->find('.remove-if-foo-bar')->size, 0;
    is $doc->find('.remove-if-foo-bar-baz')->size, 1;
    is $doc->find('*[data-plift-remove-if]')->size, 0, 'removed attr';
};

# remove-unless
subtest 'remove unless' => sub {
    is $doc->find('.remove-unless-foo')->size, 1;
    is $doc->find('.remove-unless-foo-bar')->size, 1;
    is $doc->find('.remove-unless-foo-bar-baz')->size, 0;
    is $doc->find('*[data-plift-remove-unless]')->size, 0, 'removed attr';
};


# remove-if-any
subtest 'remove if any' => sub {
    is $doc->find('.remove-if-any-foo')->size, 0;
    is $doc->find('.remove-if-any-foo-bar-baz')->size, 0;
    is $doc->find('*[data-plift-remove-if-any]')->size, 0, 'removed attr';
};

# remove-unless-any
subtest 'remove unless any' => sub {
    is $doc->find('.remove-unless-any-foo')->size, 1;
    is $doc->find('.remove-unless-any-foo-bar-baz')->size, 1;
    is $doc->find('*[data-plift-remove-unless-any]')->size, 0, 'removed attr';
};


done_testing;
