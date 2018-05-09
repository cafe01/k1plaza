package Q1::Web::Template::Plift::Filter::AppendJavascript;

use utf8;
use Moo;
use namespace::autoclean;


has 'engine' => ( is => 'ro', required => 1, weak_ref => 1 );

sub process {
    my ($self, $doc) = @_;
    my $engine = $self->engine;

    if ( my $scripts = $self->engine->context->{append_javascript} ) {

        my $outermost = $doc->find('body')->first;
        $outermost = $doc unless $doc->size;

        foreach my $script (@$scripts) {
            $outermost->append('<script type="text/javascript">'.$script.'</script>');
        }
    }

    $doc;
}



1;


__END__
=pod

=head1 NAME

Q1::Web::Template::Plift::Filter::AppendJavascript

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
