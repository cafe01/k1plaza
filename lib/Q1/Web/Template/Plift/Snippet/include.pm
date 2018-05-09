package Q1::Web::Template::Plift::Snippet::include;

use Types::Standard qw/ Bool Str /;
use Moo;
use namespace::autoclean;


has 'name'    => ( is => 'ro', isa => Str, required => 1 );
has 'replace' => ( is => 'ro', isa => Bool, default => 0 );


sub profiler_action {
    'include: '.$_[0]->name;
}


sub process {
    my ($self, $element, $engine) = @_;

    my $dom = $engine->load_template( $self->name, $element ? $element->get(0)->ownerDocument : () );

    # initial process()
    return $dom
        unless defined $element;

    # replace / append
    if ($element->tagname && $element->tagname =~ /^x-/ || $self->replace) {
        $element->replace_with($dom);
    }
    else {
        $element->append($dom);
    }

    $engine->process_element($dom);

}




1;


__END__
=pod

=head1 NAME

Q1::Web::Template::Plift::Snippet::include

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
