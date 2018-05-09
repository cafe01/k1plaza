package Q1::Web::Template::Plift::Filter::Console;

use utf8;
use Moo;
use namespace::autoclean;
use JSON::XS qw/ encode_json /;
use Scalar::Util qw/ blessed /;

sub process {
    my ($self, $doc, $engine) = @_;

    return unless $engine->environment eq 'development';
    my $stash = $engine->context;
    return unless exists $stash->{console} && ref $stash->{console} eq 'ARRAY';

    my $head = $doc->find('head')->first;
    return unless $head->size;

    # inject script into head
    my $js = '';

    foreach my $item (@{$stash->{console}}) {
        my $function = shift @$item;
        my @args = map {
            !ref     $_ ? qq/"$_"/ :
            !blessed $_ ? encode_json($_) : qq/"$_"/
        } @$item;

        $js .= sprintf "console.%s(%s); ", $function, join(', ', @args);
    }

    $engine->parse_html('<script/>')->text($js)->append_to($head);
}



1;
