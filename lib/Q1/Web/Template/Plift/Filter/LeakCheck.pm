package Q1::Web::Template::Plift::Filter::LeakCheck;

use utf8;
use Moo;
use namespace::autoclean;
use Class::Load;

has 'engine' => ( is => 'ro', required => 1, weak_ref => 1 );



sub process {
    my ($self, $doc) = @_;
    return unless $self->engine->debug;

    Class::Load::load_class('Devel::Cycle');
    Devel::Cycle::find_cycle($doc);
}

sub _fix_leak {
    my $e = shift;
    #weaken $e->tree->[3] unless isweak($e->tree->[3]);
    undef $e->tree->[3];
    $e->children->each(\&_fix_leak);
}



1;


__END__

=pod

=head1 NAME

Q1::Web::Template::Plift::Filter::LeakCheck

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
