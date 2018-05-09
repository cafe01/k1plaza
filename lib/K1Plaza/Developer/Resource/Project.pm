package K1Plaza::Developer::Resource::Project;
use Mojo::Base 'K1Plaza::Resource::DBIC';
use Data::Printer;

use mro;


sub _api {
    my $c = shift;
    $c->api('Developer::Project');
}

sub select_project {
    my $c = shift;
    my $params = $c->req->json || $c->req->params->to_hash;
    my $project_name = $params->{name} or die "missing 'name' param";

    # load project
    my $project = $c->_api->load_or_register($project_name)
        or die "Error registering project '$project_name'";

    # find/create user
    my $user_api = $c->api('User', { app_instance_id => $project->{id} });
    my $github_account = $c->developer_settings->{github_account} || {};

    my $user_data = {
        first_name => $github_account->{name}  || 'developer',
        email =>  $github_account->{email} || 'developer@k1plaza.dev',
        image_url => $github_account->{avatar_url},
        roles => ['instance_admin'],
    };

    my $user = $user_api->find({ email => $user_data->{email} })->first;
    $user = $user_api->create($user_data)->first->{object}
        unless $user;

    $user->discard_changes;

    # setup dev session and redirect to website path
    $c->log->info(sprintf "Selected project '%s' with admin user '%s'", $project_name, $user->first_name);
    $c->session->{project} = {
        name => $project->{name},
        canonical_alias => $project->{canonical_alias},
        session_user => { $user->get_columns }
    };

    $c->rendered(200);
    # $c->redirect_to($params->{continue} || '/');
}


1;
