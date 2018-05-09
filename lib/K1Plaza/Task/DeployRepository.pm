package K1Plaza::Task::DeployRepository;

use Mojo::Base 'Mojolicious::Plugin';


sub register {
    my ($self, $app) = @_;

    $app->minion->add_task($_ => $self->can("_$_"))
        for qw/ migrate_unmanaged_app deploy_master_repository deploy_app_repository /;
}



sub _migrate_unmanaged_app {
    my ($job, $params) = @_;
    my $app = $job->app;
    my $api = $app->api('AppInstance');
    my $app_instance = $api->resultset->find($params->{app_id})
        or return $job->fail("app id='$params->{app_id}' not found.");

    # get master repo
    my $url = $params->{repository_url}
        or return $job->fail("missing 'repository_url' task param.");

    my $master_repository = $api->get_master_repository($url, { clone => 1 })
        or return $job->fail(sprintf "get_master_repository(%s) error.", $url);

    # deploy repository
    $app_instance->base_dir(undef);
    $app_instance->is_managed(1);
    $app_instance->repository_url($url);
    my $res = $api->deploy_repository($app_instance, $master_repository);
    $job->fail(sprintf "deploy_repository('%s', '%s') error: %s", $app_instance->name, $master_repository->git_dir, $res->{error})
        if $res->{error};

    # finish
    my $commit = $res->{deployment_repository}->get_branch('master')->peel('commit');
    $job->finish(sprintf "'%s' migrated to '%s' commit '%s' (%s)",
        $app_instance->name,
        $res->{deployment_repository}->git_dir,
        $commit->message =~ s/\n//gr,
        substr($commit->id, 0, 8)
    )
}


sub _deploy_master_repository {
    my ($job, $url) = @_;
    my $app = $job->app;
    my $api = $app->api('AppInstance');

    my $master_repository = $api->get_master_repository($url, { clone => 1 })
        or return $job->fail(sprintf "get_master_repository(%s) error.", $url);

    $master_repository->fetch;

    my $commit = $master_repository->get_branch('master')->peel('commit')
        or return $job->fail("get_branch('master') failed.");

    my $commit_msg = $commit->message;
    chomp $commit_msg;
    my $message = sprintf "master is now at %s '%s'", $commit->id, $commit_msg;
    $app->log->info($message);
    $job->finish($message);
}

sub _deploy_app_repository {
    my ($job, $app_id) = @_;
    my $app = $job->app;
    my $api = $app->api('AppInstance');
    my $app_instance = $api->resultset->find($app_id)
        or return $job->fail("app id='$app_id' not found.");

    return $job->fail("app '".$app_instance->name."' is not managed.")
        unless $app_instance->is_managed;

    my $master_repository = $api->get_master_repository($app_instance->repository_url, { clone => 1 })
        or return $job->fail(sprintf "get_master_repository(%s) error.", $app_instance->repository_url);

    my $res = $api->deploy_repository($app_instance, $master_repository);
    $job->fail(sprintf "deploy_repository('%s', '%s') error: %s", $app_instance->name, $master_repository->git_dir, $res->{error})
        if $res->{error};

    my $commit = $res->{deployment_repository}->get_branch('master')->peel('commit');
    $job->finish(sprintf "'%s' deployed on '%s' commit '%s' (%s)",
        $app_instance->name,
        $res->{deployment_repository}->git_dir,
        $commit->message =~ s/\n//gr,
        substr($commit->id, 0, 8)
    );

    # TODO send email
}





1;
