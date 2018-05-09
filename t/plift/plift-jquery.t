#!/usr/bin/env perl
use Test::More;
use strict;
use FindBin;
use lib 'lib';
use lib 't/lib';
use lib $FindBin::Bin ."/lib";
use Data::Dumper;
use utf8;
use DateTime;


BEGIN {
    use_ok 'Q1::Web::Template::Plift';
}

my $plift = Q1::Web::Template::Plift->new( include_path => [$FindBin::Bin ."/templates/"] );

# parse_html
isa_ok $plift->parse_html('<div/>'), 'Q1::Web::Template::Plift::jQuery', 'parse_html';
isa_ok $plift->process('layout'), 'Q1::Web::Template::Plift::jQuery';


# datetime


test_render_data();

done_testing;


sub test_render_data {

    my $now = DateTime->now;
    my $schema = {
        title => 'h1',
        subtitle => { selector => 'h2', at => 'text, @title', data_key => 'title' },
        url   => { 'a.link' => '@href text' },
        body  => { selector => 'p', at => 'html', data_key => 'content' },
        empty => { selector => 'foo', default => 'bar' },
        now   => { selector => 'now', format_date => '%A %F %T' },
        tags  => {
            selector => '.tag',
            schema => {
                name => '.name',
                url  => { selector => 'a', at => '@href' }
            }
        },
        metadata => {
            selector => '.info',
            schema => {
                duration => '.duration',
                rating => '.rating'
            }
        },
        callback => {
            selector => 'callback',
            data_key => 'title',
            callback => sub { shift->text(shift.' from cb') }
        }
    };

    my $data = {
        title => 'title',
        url => 'url',
        content => '<div>the content</div>',
        tags => [{ name => 'tag1', url => 'url1' }, { name => 'tag2', url => 'url2' }, { name => 'tag3', url => 'url3' }],
        metadata => { duration => 420, rating => 5 },
        empty => undef,
        now => $now
    };

    my $el = $plift->load_template('render_data');
    $el->render_data($schema, $data);
    # diag $el->as_html;

    is $el->find('h1')->first->text, $data->{title}, 'title';
    is $el->find('h1.custom-at')->text, 'title', 'data-plift-render-at';
    is $el->find('h1.custom-at')->attr('title'), 'title', 'data-plift-render-at';
    is $el->find('*[data-plift-render-at]')->size, 0, 'attr data-plift-render-at removed';
    is $el->find('foo')->text, 'bar', 'foo (default)';
    is $el->find('h2')->text, 'title', 'h2';
    is $el->find('h2')->attr('title'), 'title', 'h2';
    is $el->find('p')->html, $data->{content}, 'content';
    is $el->find('a.link')->text, 'url', 'url';
    is $el->find('a.link')->attr('href'), 'url', 'url';
    is $el->find('.duration')->text, $data->{metadata}{duration}, 'metadata - duration';
    is $el->find('.rating')->text, $data->{metadata}{rating}, 'metadata - rating';
    is $el->find('now')->text, $now->strftime($schema->{now}{format_date}), 'format_date';
    is $el->find('callback')->text, $data->{title}.' from cb', 'callback';

    # tags
    is $el->find('.tag')->size, scalar(@{$data->{tags}}), 'tag items';
    is $el->find('.tag .name')->first->text, $data->{tags}[0]{name}, 'tag name';

    # array data
    diag "array data";
    $el = $plift->load_template('render_data');
    $el->find('.tag')->render_data($schema->{tags}{schema}, $data->{tags});
    is $el->find('.tag')->size, scalar(@{$data->{tags}}), 'tag items';
    is $el->find('.tag .name')->first->text, $data->{tags}[0]{name}, 'tag name';
    # diag Dumper $schema->{tags}, $data->{tags};
    # diag $el->as_html;
}
