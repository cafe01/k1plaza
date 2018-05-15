package K1Plaza::Developer::Resource::Project;
use Mojo::Base 'K1Plaza::Resource::DBIC';
use Data::Dumper;
use Data::Printer;
use Mojo::File;
use Mojo::Util qw/ encode  /;
use Mojo::JSON qw/ from_json encode_json decode_json /;
use Mojo::IOLoop;
use Try::Tiny;

use mro;


sub _api {
    my $c = shift;
    $c->api('Developer::Project');
}

sub create {
    my $c = shift;
    my $req = $c->req;
    my $log = $c->log;
    my $params = $req->json || $req->params->to_hash;

    return $c->rendered(400) unless $params->{name};

    my $projects_dir = Mojo::File->new('/projects');
    die "Missing directory /projects" unless -d $projects_dir;

    # error: invalid name
    unless ($params->{name} =~ /^[a-zA-Z0-9_-]+$/) {
        $log->error("Nome do projeto deve conter apenas os caracteres [a-zA-Z0-9_-].");
        $c->res->code(400);
        return $c->render(json => {
            success => \0,
            error => 'INVALID_NAME'
        });
    }

    # error: project already exists
    if (-e $projects_dir->child($params->{name})) {
        $c->res->code(400);
        return $c->render(json => {
            success => \0,
            error => 'PROJECT_EXISTS'
        });
    }

    # create dir
    my $dir = $projects_dir->child($params->{name});
    $dir->make_path;
    $dir->child("app.yml")->spurt(encode 'UTF-8', sprintf "description: %s\n", $params->{description} || "O fabuloso website $params->{name}");

    $c->render(json => {
        success => \1
    });
}

sub ws_create {
    my $c = shift;
    my $log = $c->log;

    # Opened
    $c->app->log->debug('WebSocket opened');

    # Increase inactivity timeout for connection a bit
    $c->inactivity_timeout(300);

    # Incoming message
    my $started = 0;
    my $access_token = $c->developer_settings->{github_access_token};

    # ws message
    $c->on(message => sub {
        my $c = shift;
        return if $started;
        my $params = from_json shift;
        $started = 1;

        Mojo::IOLoop->subprocess(sub {
            my $res;
            try {
                # git clone on subprocess        
                $res = $c->api('Developer::Project')->create({
                    %$params,
                    github_access_token => $access_token,
                    #  TODO send progress via pubsub
                    # sideband_progress => sub { $c->send(encode_json { type => 'sideband_progress', message => shift }) },
                    # transfer_progress => sub { 
                    #     my $info = shift;
                    #     my %data = map { $_ => $info->$_ } qw/ total_objects received_objects received_bytes /;
                    #     $c->send(encode_json { type => 'transfer_progress', %data }) ;
                    #     # $c->send(encode_json { type => 'transfer_progress', %data }) ;
                    # },
                });

                delete $res->{project_repository};
            } catch {
                warn "error: @_";
            };

            $res;
        },
        sub {
            my ($subprocess, $err, $res) = @_;

            if ($err) {
                $log->debug("[subprocess error] $err");
                $c->send(encode_json { error => $err });
                return $c->finish;
            }

            # register website
            my $register_res = $c->api('AppInstance')->register_app({ 
                name => $params->{name}, 
                base_dir => $res->{project_directory} 
            });
            
            unless ($register_res->{success}) {
                $log->error("[register_app error] ", Dumper $register_res);
                $res = $register_res;
            }

            # finish
            $res->{type} = 'result';
            $c->send(encode_json $res);            
            $c->finish();
        });
    });

    $c->on(error => sub {
        $log->error("[ws error] ", @_);
    });

    # Closed
    $c->on(finish => sub {
        my ($c, $code) = @_;
        $log->debug("WebSocket closed with status $code)");
    });
}


sub select_project {
    my $c = shift;
    my $params = $c->req->json || $c->req->params->to_hash;

    # load project
    my $project = $c->_api->load_or_register($params)
        or die "Error registering project";

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
    $c->log->info(sprintf "Selected project '%s' with admin user '%s'", $project->{name}, $user->first_name);
    $c->session->{project} = {
        name => $project->{name},
        canonical_alias => $project->{canonical_alias},
        session_user => { $user->get_columns }
    };

    $c->rendered(200);
    # $c->redirect_to($params->{continue} || '/');
}


1;
