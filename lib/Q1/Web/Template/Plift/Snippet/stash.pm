package Q1::Web::Template::Plift::Snippet::stash;

use utf8;
use Moo;
use Types::Standard qw/ ArrayRef HashRef Bool Str /;
use namespace::autoclean;


has 'key' => ( is => 'rw', isa => Str );


sub process {
	my ($self, $element, $engine) = @_;
	#printf STDERR "[+] stash '%s'\n", $element->as_html;
    $element->text($engine->context->{$self->key} || 'stash stuff here');
}



1;


__END__
=pod

=head1 NAME

Q1::Web::Template::Plift::Snippet::stash

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
