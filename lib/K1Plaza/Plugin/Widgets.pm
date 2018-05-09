package K1Plaza::Plugin::Widgets;

use Mojo::Base 'Mojolicious::Plugin';
use Q1::API::Widget::Manager;
use Data::Printer;

sub register {
    my ($self, $app) = @_;

    my $widget_manager = Q1::API::Widget::Manager->new( app => $app );
    $app->helper(widget => sub {
        return unless $_[1];
        $widget_manager->get_widget_by_name(@_);
    });
}


1;
