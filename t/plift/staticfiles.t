#!/usr/bin/env perl

use Test::More 'no_plan';
use Test::Exception;
use strict;
use FindBin;
use lib 'lib';
use lib 't/lib';
use Data::Dumper;
use Cwd;
use Q1::Web::Template::Plift;
use Path::Tiny;
use JSON qw/decode_json/;

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/filter/"],
    static_path  => [$FindBin::Bin ."/templates/filter/"],
    filters      => ['StaticFiles'],
    environment  => 'development'
);

$plift->context->{_sass_private_paths} = [$FindBin::Bin];

my $css_dir = path($FindBin::Bin ."/templates/filter/css/");
$css_dir->remove_tree;

my $output = $plift->process('staticfiles')->as_html;


like $output, qr!<a href="/link.html">link</a>!, 'StaticFiles filter - href';
like $output, qr!<img src="/images/logo.jpg">!, 'StaticFiles filter - src';

# sass
like $output, qr!<link href="/css/screen\.css\?v=\w+" rel="stylesheet">!, 'StaticFiles filter - Sass';
like $css_dir->child("screen.css")->slurp, qr!sourceMappingURL=screen\.css\.map!, 'compiled css';
like $css_dir->child("screen.css.version")->slurp, qr/\w+/, 'css version file';
is $css_dir->child("screen-production.css")->slurp, ".weed{color:green}", 'compiled minified css';

is_deeply decode_json($css_dir->child("screen.css.map")->slurp), {
    'mappings' => 'ACAA,AAAA,KAAK,CAAC;EACF,KAAK,EDDD,KAAK,GCEZ',
    'file' => 'screen.css',
    'names' => [],
    'version' => 3,
    'sources' => [ '../sass/screen.scss', '../sass/_partial.scss' ]
}, 'sourcemap file';

# sass on production
$plift->environment('production');
like $plift->process('staticfiles')->as_html, qr!<link href="/css/screen-production\.css\?v=\w+" rel="stylesheet">!, 'sass on production';

# StaticFiles, with uri_for_static()
$plift->filters([]);
$plift->add_filter('StaticFiles', { uri_for_static => sub { "/test/static/$_[0]" }});
$output = $plift->process('staticfiles')->as_html;

like $output, qr!<img src="/images/logo.jpg">!, 'StaticFiles filter - with uri_for_static()';
like $output, qr!<link href="/css/ie8.css" />!, 'StaticFiles filter - replaced commented out paths';


# cleanup
#system "rm ". $FindBin::Bin ."/templates/filter/css/*";
