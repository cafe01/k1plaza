package Q1::Web::Template::Plift::Snippet::script;

use utf8;
use Moo;
use Types::Standard qw/ Str /;
use namespace::autoclean;


has 'script_source', is => 'ro', isa => Str, required => 1;
has 'description',   is => 'ro', isa => Str, default => '<inline>';
has 'inline', is => 'ro', isa => Str, default => 0;


sub profiler_action {
    sprintf "script: '%s'", $_[0]->description;
}


sub process {
	my ($self, $element, $engine, $params) = @_;

    # parse js
    my $wrapper = q!
        var $ = function(){
            return arguments[0].match(/</) ? engine.parse_html(arguments[0])
                                           : element.find(arguments[0]);
        };
        %s
    !;

    $wrapper =~ s/\n/ /g;

    my $console_data = ($engine->context->{console} ||= []);
    my %console = map {
        my $cmd = $_;
        $cmd => sub { push @$console_data, [$cmd, @_] }
    } qw/ log info warn error /;


    $params = {} if $self->inline;


    # run code
    my $code = $engine->javascript_context
                      ->eval_wrapped(sprintf($wrapper, $self->script_source), $self->description, {
                          element => $self->inline ? $element->parent : $element,
                          engine => $engine,
                          params => $params,
                          console => \%console,
                          tx => $engine->context->{tx}
                      });

	# remove script element
	$element->detach if $self->inline;

    if ($element->tagname =~ /^x-/) {

        unless ($element->attr('keep-x-tag')) {
            $element->replace_with($element->contents)
        }

        $element->remove_attr('keep-x-tag');
    }
}



1;


__END__

=pod

=head1 NAME

Q1::Web::Template::Plift::Snippet::script

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
