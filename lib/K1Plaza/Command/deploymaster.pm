package K1Plaza::Command::deploymaster;
use Mojo::Base 'Mojolicious::Commands';
use Data::Printer;

has description => 'Deploy app master repository.';
has usage       => 'k1plaza deploymaster <git url>';

sub run {
    my ($self, $url) = @_;
    die $self->usage."\n" unless $url;

    my $app = $self->app;
    my $taskid = $app->minion->enqueue(deploy_master_repository => [$url]);
    $app->log->debug("Enqueued task deploy_master_repository($url) id $taskid");

    $app->minion->perform_jobs if $app->mode eq 'development';
}


1;
