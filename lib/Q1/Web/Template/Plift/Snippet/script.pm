package Q1::Web::Template::Plift::Snippet::script;

use utf8;
use Moo;
use Types::Standard qw/ Str /;
use namespace::autoclean;


has 'script_source', is => 'ro', isa => Str, required => 1;
has 'description',   is => 'ro', isa => Str, default => '<inline>';
has 'inline', is => 'ro', isa => Str, default => 0;
has 'file', is => 'ro', isa => Str;


sub profiler_action {
    sprintf "script: '%s'", $_[0]->description;
}


sub process {
	my ($self, $element, $engine, $params) = @_;

    # parse js
    my $js_code_wrapper = q!
    (function(){
        var tx = require('tx'),
            engine = require('plift'),
            params = require('params'),
            element = require('element'),
            $ = function(stuff){ return stuff.match(/</) ? engine.parse_html(stuff) : element.find(stuff) };
        %s
    })()
    !;

    # parse js
    $js_code_wrapper =~ s/\n/ /g;

    # console
    my $console_data = ($engine->context->{console} ||= []);
    my %console = map {
        my $cmd = $_;
        $cmd => sub { push @$console_data, [$cmd, @_] }
    } qw/ log info warn error /;

    # inject modules
    my $js = $engine->javascript_context;
    local $js->modules->{tx} = $engine->context->{tx} || {};
    local $js->modules->{plift} = $engine;
    local $js->modules->{params} = $self->inline ? {} : $params;
    local $js->modules->{element} = $self->inline ? $element->parent : $element;
    local $js->modules->{console} = \%console;

    # run code
    my $js_code = sprintf($js_code_wrapper, $self->script_source);
    $js->eval($js_code, $self->description);

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
