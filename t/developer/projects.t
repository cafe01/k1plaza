#!/usr/bin/env perl
use Test::K1Plaza;
use FindBin;
use Mojo::File qw/ path /;

my $app = app();
$app->schema->deploy({ add_drop_table => 1 });

my $workspace = path("$FindBin::Bin/projects");
$app->config->{developer_workspace} = "$workspace";

my $api = $app->api('Developer::Project');


subtest 'list' => sub {

    my $res = $api->list;
    # p $res;
    my $item = $res->{items}[0];
    like $item->{name}, qr/^\w+$/, 'name';
    is $item->{base_dir}, "$FindBin::Bin/projects/$item->{name}", 'base_dir';
    # ok $res->{total} > 0, 'total';
};

subtest 'create' => sub {

    my $project_dir = $workspace->child("super-project");
    $project_dir->remove_tree if -d $project_dir;

    my $res = $api->create({
        name => "Super Project",
        repository_name => "cafe01/q1plaza-test-site",
        # sideband_progress => sub {
        #     diag "[sideband_progress] @_"
        # },
        # transfer_progress => sub {
        #     diag "[transfer_progress] @_"
        # }
    });
    
    is $res->{success}, 1;
    ok -f $project_dir->child('app.yml'), 'project app.yml is there';

    my $repo = $res->{project_repository};
    is [$repo->raw->remotes], [], 'no origin';

    # cleanup
    $project_dir->remove_tree;
};



done_testing;
