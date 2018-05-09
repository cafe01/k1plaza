package K1Plaza::Backoffice::Resource::Apps;
use Mojo::Base 'K1Plaza::Resource::DBIC';
use Data::Printer;

sub _api {
    my $c = shift;
    $c->api('AppInstance')->order_by(\'created_at DESC');
}


sub create {
    my ($c) = @_;
    my $data = $c->req->json;

    # prepare hostnames
    my @hostnames;
    foreach (@{$data->{hostnames}}) {
        $_->{environment} ||= 'production';
        push @hostnames, $_;
    }

    # create
    my $api = $c->api('AppInstance');
    my $res;
    if ($data->{repository_url}) {

        $res = $api->register_managed_app({
            name => $data->{name},
            repository_url => $data->{repository_url},
            alias => \@hostnames
        });

        if ($res->{success}) {
            $res->{items} = [{ $res->{app}->get_columns }];
            delete $res->{master_repository};
            delete $res->{deployment_repository};
            delete $res->{app};
        }
    }
    else {
        # check app folder exists
        return $c->rendered(400) unless -d $c->app->path_to("app_instances/$data->{name}");

        $res = $api->register_app($data->{name}, \@hostnames);
    }

    unless ($res->{success}) {
        $c->res->code(400);
        return $c->render(json => $res);
    }

    # respond

    my $new_id = $res->{items}[0]->{'id'};

    # redirect
    my $uri = $c->req->url->clone;
    $uri->path->trailing_slash(1)->merge($new_id);
    $c->res->code(303); # See Other
    $c->redirect_to($uri->path_query);
}



sub deploy_repository {
    my ($c) = @_;

    my $params = $c->req->query_params->to_hash;
    return $c->rendered(400) unless $params->{appid};

    my $api = $c->api('AppInstance');
    my $app = $api->resultset->find($params->{appid})
        or return $c->render(json => { success => \0, error => 'ERROR_UNKOWN_APP' });

    return $c->render(json => { success => \0, error => 'ERROR_UNMANAGED_APP' }) unless $app->is_managed;
    return $c->render(json => { success => \0, error => 'ERROR_MISSING_REPO_URL' }) unless $app->repository_url;

    my $minion = $c->minion;
    my $master_task_id =  $minion->enqueue(deploy_master_repository => [$app->repository_url]);

    $c->render(json => {
        success => \1,
        tasks => {
            deploy_master_repository => $master_task_id,
            deploy_app_repository => $minion->enqueue(deploy_app_repository => [$app->id] => { parents => [$master_task_id] }),
        }
    });
}

sub github_webhook {
    my ($c) = @_;
    my $api = $c->api('AppInstance');
    my $app = $c->app;
    my $log = $app->log;
    my $data = $c->req->json;
    # p $data;

    # only follow master branch
    unless ($data->{ref} eq 'refs/heads/master') {
        $log->info("Received github webhook for untracked ref '$data->{ref}'") if $data->{ref};
        return $c->render(text => "Thanks, but I'm only interest on the master branch. :)");
    }

    # do we host this repo?
    my $repo_ssh_url = $data->{repository}{ssh_url};
    my $master_repository = $api->get_master_repository($repo_ssh_url);
    unless ($master_repository) {
        $log->info("Received github webhook for unknown repository '$data->{repository}{html_url}'");
        return $c->render(text => "Thanks, but I don't know this repo. :)");
    }

    # update master repo
    my $master_task_id = $c->minion->enqueue(deploy_master_repository => [$repo_ssh_url]);
    $log->info(sprintf "task %d: deploy_master_repository('%s')", $master_task_id, $repo_ssh_url);
    # $log->info("Updating master repository ".$master_repository->git_dir);

    # update websites
    my @repo_urls = grep {defined } @{$data->{repository}}{'ssh_url','clone_url','git_url'};
    die "Could not find repository urls in webhook payload!" unless @repo_urls;

    my @target_apps = $api->resultset->search({ repository_url => \@repo_urls });
    # my @purge_hostnames;

    foreach my $app (@target_apps) {
        # $log->info(sprintf "Deploying github update for app '%s': %s (%s)", $app->canonical_alias, $data->{head_commit}{message}, $data->{head_commit}{id});
        my $app_repository = $api->get_app_repository($app);
        if ($app_repository->raw->is_head_detached) {
            $log->info("Repository is deatched, skipping.");
            next;
        }

        my $task_id = $c->minion->enqueue(deploy_app_repository => [$app->id] => { parents => [$master_task_id] });
        $log->info(sprintf "task %d: deploy_app_repository(%d)", $task_id, $app->id);
        # push @purge_hostnames, $app->canonical_alias;
    }

    # purge cloudflare's cache
    # my $purged_urls = [];
    # if ($app->config->{cloudflare_cdn_zone_id}) {
    #     $purged_urls = $c->_purge_cloudflare_cache($data->{commits}, \@purge_hostnames);
    # }

    # notify developers
    # $c->api('Mail')->send_mail({
    #     from       => '"K1Plaza Backoffice" <donotreply@q1software.com>',
    #     to         => 'contato@q1software.com',
    #     subject    => sprintf('%s is now at "%s"', $data->{repository}{full_name}, $data->{head_commit}{message}),
    #     template   => 'email/repository_deployed.tt',
    #     template_include_path => $c->template_include_path,
    #     template_data  => {
    #         payload => $data,
    #         hostnames => \@purge_hostnames,
    #         purged_urls => $purged_urls
    #     }
    # });

    $c->render( text => 'THANKS' );
}


# sub _purge_cloudflare_cache {
#     my ($c, $commits, $hostnames) = @_;
#     my $cdn_host = $c->app->config->{cdn_host};
#
#     my @files = map {
#         (@{$_->{removed}}, @{$_->{modified}})
#     } @$commits;
#
#     my @urls;
#
#     foreach my $file (@files) {
#         my ($static_path) = $file =~ /(?:^|\/)static\/(.*)/;
#         next unless $static_path;
#         push @urls, "http://$cdn_host/$_/.static/$static_path"
#             for @$hostnames;
#     }
#
#     $c->log->debug("Purging Cloudflare cache:\n".join("\n", @urls));
#
#     my $cloudflare = $c->api('Cloudflare');
#     my $zone_id = $c->app->config->{cloudflare_cdn_zone_id};
#
#     my $res = $cloudflare->request('DELETE', "zones/$zone_id/purge_cache", { files => \@urls });
#     return \@urls if $res->{success};
#
#     $c->log->error("Error purging cloudflare cache: ". join("\n", @{$res->{errors}}));
#     return [];
# }

1;
