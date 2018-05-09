package K1Plaza::Command::deploy;
use Mojo::Base 'Mojolicious::Commands';
use Data::Printer;

has description => 'Deploy database tables.';
has usage       => 'k1plaza deploy';
# has namespaces => sub { ['Mojolicious::Command::generate'] };

sub run {
    my ($self, $name) = @_;
    my $app = $self->app;
    $app->schema->deploy({ add_drop_table => $app->mode eq 'development' });
}


1;
