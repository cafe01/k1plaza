package K1Plaza::Command::eavdeploy;
use Mojo::Base 'Mojolicious::Commands';
use Data::Printer;
use Mojo::File 'path';
use Mojo::JSON qw(decode_json);

has description => 'Dploy EAV tables.';
has usage       => 'k1plaza eavdeploy [droptables]';

sub run {
    my ($self, $drop_tables) = @_;

    my $log = $self->app->log;
    my $c = $self->app->build_controller;

    my $add_drop_table = $drop_tables && $drop_tables eq 'droptables' ? 1 : 0;
    $log->info("Calling EAV API deploy( add_drop_table => $add_drop_table )");
    $self->app->api('EAV')->schema->deploy(add_drop_table => $add_drop_table);
}


1;
