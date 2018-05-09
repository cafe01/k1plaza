package K1Plaza::Command::migrateapp;
use Mojo::Base 'Mojolicious::Commands';
use Data::Printer;
use Mojo::File 'path';
use Mojo::JSON qw(decode_json);

has description => 'Migrate app to managed repository.';
has usage => 'migrateapp <name> <repo url>';

sub run {
    my ($self, $name, $repo) = @_;
    die $self->usage."\n" unless $name && $repo;

    my $log = $self->app->log;

    my $app_instance = $self->app->schema->resultset('AppInstance')->single({ name => $name })
        or die "app '$name' not found";

    my $taskid = $self->app->minion->enqueue( migrate_unmanaged_app => [{
        app_id => $app_instance->id,
        repository_url => $repo
    }]);

    $log->info("task $taskid: migrate_unmanaged_app");
}


1;
