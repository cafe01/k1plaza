package K1Plaza::Command::appdeploy;
use Mojo::Base 'Mojolicious::Commands';
use Data::Printer;

has description => 'Deploy managed apps repository.';
has usage       => 'k1plaza appdeploy [name]';

sub run {
    my ($self, $name) = @_;
    my $app = $self->app;
    my $log = $app->log;
    my $api = $app->api('AppInstance');

    my @apps = $api->resultset->search({
        is_managed => 1,
        $name ? (name => $name) : (),
    }, { order_by => 'name' });

    foreach my $app_instance (@apps) {

        unless ($app_instance->repository_url) {
            $log->warn(sprintf "missing repository_url for app %s", $app_instance->name);
            next;
        }

        my $master_task_id = $app->minion->enqueue(deploy_master_repository => [$app_instance->repository_url]);
        $log->info(sprintf "[%s] task %d: deploy_master_repository('%s')", $app_instance->name, $master_task_id, $app_instance->repository_url);

        my $task_id = $app->minion->enqueue(deploy_app_repository => [$app_instance->id] => { parents => [$master_task_id] });
        $log->info(sprintf "[%s] task %d: deploy_app_repository('%s')", $app_instance->name, $task_id, $app_instance->id);
    }

}


1;
