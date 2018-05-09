package Q1::Utils::Log;

use Moo;
use namespace::autoclean;

=head1 NAME

Q1::Utils::Log

=head1 DESCRIPTION

Simple log class. Has the same API as the Catalyst logger.

=cut





=head1 METHODS

=head2 debug

=cut

sub debug {
    my ($self, @lines) = @_;
    $self->_log('[debug]', \@lines);
}


=head2 info

=cut

sub info {
    my ($self, @lines) = @_;
    $self->_log('[info]', \@lines);
}


=head2 warn

=cut

sub warn {
    my ($self, @lines) = @_;
    $self->_log('[warn]', \@lines);
}


=head2 error

=cut

sub error {
    my ($self, @lines) = @_;
    $self->_log('[error]', \@lines);
}


=head2 fatal

=cut

sub fatal {
    my ($self, @lines) = @_;
    $self->_log('[fatal]', \@lines);
}



=head2 _log

=cut

sub _log {
    my ($self, $prefix, $lines) = @_;
    printf STDERR "%s %s\n", $prefix, join( "\n", @$lines);
}


1;
