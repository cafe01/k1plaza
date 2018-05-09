package Q1::Web::Template::Plift::Filter::OpenGraph;

use utf8;
use Moo;
use namespace::autoclean;
use Data::Dumper;

has 'engine' => ( is => 'ro', required => 1, weak_ref => 1 );

sub process {
    my ($self, $doc) = @_;

    my $head = $doc->find('head')->first;
    return unless $head->size;

    my $engine = $self->engine;
    my $tx = $engine->context->{tx};

    my $app_instance_og = $tx && $tx->has_app_instance ? $tx->app_instance->config->{opengraph} || {} : {};
    my $stash = $engine->context;
    my $og = $stash->{opengraph} || {};
    my $meta = $stash->{meta} || {};

    %$og = (
        type  => 'website',
        %$app_instance_og,
        $stash->{title} ? (title => $stash->{title}) : (),
        %$og
    );

    if ($tx) {

        my $req = $tx->req;
        $og->{url} ||= $req->url->to_abs->to_string;

        $og->{image} = $tx->uri_for_static($og->{image})
            if $tx && $og->{image} && $og->{image} !~ /^http/;
    }



    $self->_process_metatags($head, $meta);
    $self->_process_opengraph($head, $og);
}

sub _process_metatags {
    my ($self, $head, $meta) = @_;
    my $meta_el = $self->engine->parse_html('<meta/>');

    foreach my $name (keys %$meta) {

        my $el = $head->find('meta[name="'.$name.'"]');

        if ($el->size)  {
            $el->attr('content', $meta->{$name});
        }
        else {

            $meta_el->clone->attr({ name => $name, content => $meta->{$name} })
                    ->append_to($head);
        }
    }
}


sub _process_opengraph {
    my ($self, $head, $og) = @_;

    # prepare items
    my @items;
    while ( my($key, $val) = each %$og) {

        if (ref $val eq 'HASH') {
            foreach my $subkey (keys %$val) {
                push @items, _item("$key:$subkey", $val->{$subkey});
            }
            next;
        }

        push @items, _item("og:$key", $val);
    }

    # warn Dumper \@items;

    # create tags
    my $meta_el = $self->engine->parse_html('<meta/>');
    foreach my $item (@items) {

        $meta_el->clone
                ->attr({ property => $item->[0], content => $item->[1] })
                ->append_to($head);
    }
}


sub _item {
    my ($key, $value) = @_;
    return () unless defined $value;

    # array
    return map { [$key, _format_value($_)] } @$value
        if ref $value eq 'ARRAY';

    return [$key, _format_value($value)];
}

sub _format_value {
    my $val = shift;
    $val = "$val";
    $val =~ s/\n/ /g;
    $val;
}



1;


__END__
=pod

=head1 NAME

Q1::Web::Template::Plift::Filter::OpenGraph

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
