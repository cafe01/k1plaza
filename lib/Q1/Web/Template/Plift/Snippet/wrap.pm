package Q1::Web::Template::Plift::Snippet::wrap;

use utf8;
use Moo;
use Types::Standard qw/ Bool Str /;
use namespace::autoclean;
use Carp;
use Q1::jQuery;


has 'with'    => ( is => 'ro', isa => Str, default => 'layout' );
has 'at'      => ( is => 'ro', isa => Str, default => 'content' );
has 'content' => ( is => 'ro', isa => Bool, default => 0 );
has 'replace' => ( is => 'ro', isa => Bool, default => 0 );


sub profiler_action { 'wrap: '.$_[0]->with }

sub deferred { 1 }

sub process {
    my ($self, $element, $engine) = @_;
    my $ctx = $engine->context;
    my $dom = $engine->load_template( $self->with, $element->get(0)->ownerDocument );

    # $dom elements comes unbound of document, insert somewhere
    # and insert before process_element() so future widgets can see the whole document
    $dom->insert_after($element);
    $engine->process_element($dom);

    # find wrapper
    my $wrapper = $dom->find('#'.$self->at)->first;
    $wrapper = $dom->first if $wrapper->size == 0 && $dom->attr('id') eq $self->at;

    confess "wrap error: can't find wrapper element (with id '".$self->at."') on:\n".$dom->as_html
        unless $wrapper->size > 0;

    # wrap element
    my $is_xtag = $element->tagname =~ /^x-/;
    if ($self->replace) {
        $wrapper->replace_with($is_xtag || $self->content ? $element->contents : $element);
    }
    else {
        $wrapper->append($is_xtag || $self->content ? $element->contents : $element);
    }
    $element->remove if $is_xtag;
}




1;


__END__

=pod

=head1 NAME

Q1::Web::Template::Plift::Snippet::wrap

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

includes the content of other template into the element

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
