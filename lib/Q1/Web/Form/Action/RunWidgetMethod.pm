package Q1::Web::Form::Action::RunWidgetMethod;

use utf8;
use Moose;
use namespace::autoclean;

has [qw/ widget_name widget_method /] => ( is => 'ro', isa => 'Str', required => 1 );

has 'method_args' => ( is => 'rw', default => sub {[]} ) ;


sub process  {
    my ($self, $ctx) = @_;
    my $app  = $ctx->{app};
    my $form = $ctx->{form};

    # get widget
    my $widget = $app->widget($self->widget_name);
    return unless $widget;

    # get method
    my $method = $widget->can($self->widget_method);
    return unless $method;

    # run method    
    my $args = $self->method_args;
    $widget->$method($form->values, ref($args) eq 'ARRAY' ? @$args : $args);
}





__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=head1 NAME

Q1::Web::Form::Action::RunWidgetMethod

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head2 call

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
