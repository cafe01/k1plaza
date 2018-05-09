package Snippet::AppendJavascript;

use Moo;

sub process {
	my ($self, $el, $engine) = @_;
	push @{$engine->context->{append_javascript}}, "jscode";
}

1;
