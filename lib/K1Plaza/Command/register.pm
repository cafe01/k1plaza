package K1Plaza::Command::register;
use Mojo::Base 'Mojolicious::Commands';
use Data::Printer;

has description => 'Register app instance.';
has usage       => 'k1plaza register <appname>';
# has namespaces => sub { ['Mojolicious::Command::generate'] };

sub run {
    my ($self, $name) = @_;

    my $res = $self->app->api('AppInstance')->register_app($name);
    p $res;
}


1;
