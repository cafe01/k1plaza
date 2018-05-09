package K1Plaza::API::Developer::Project;

use Mojo::Base -base;
use Mojo::File 'path';
use Git::Raw;
use Data::Printer;
use K1Plaza::Sitemap;

has 'tx';


sub list {
    my ($self, $params) = @_;
    $params->{page} //= 1;
    $params->{limit} //= 10;
    $params->{start} = $params->{limit} * $params->{page} - $params->{limit};

    # developer workspace
    my $workspace = path($self->tx->config->{developer_workspace})->to_abs;

    # find projects
    my $app_instances = $self->tx->api('AppInstance');
    my @folders = grep { -e $_->child('app.yml') } $workspace->list({ dir => 1 })->each;

    if ($params->{search}) {
        my $query = quotemeta $params->{search};
        @folders = grep { $_->basename =~ /$query/i } @folders
    }

    # sort by last commit time
    my @projects = sort {
        my $a_time = $a->{git} ? $a->{git}{last_commit}{time} : 0;
        my $b_time = $b->{git} ? $b->{git}{last_commit}{time} : 0;

        defined $a->{git} <=> defined $b->{git}
            ||
        $b_time <=> $a_time;
    } map {

        my $dir = $_;
        my $project = {
            name     => $dir->basename,
            base_dir => $dir,
        };

        # git info
        if (-d $dir->child('.git') ) {

            my $repo = Git::Raw::Repository->open($dir->child('.git')->to_string);
            my $last_commit = $repo->head->peel('commit');

            $project->{git} = {
                repo => $repo,
                origin => undef,
                last_commit => {
                    id => $last_commit->id,
                    message => $last_commit->message,
                    time => $last_commit->time,
                    author => {
                        name => $last_commit->author->name,
                        email => $last_commit->author->email,
                    }
                }
            };
        }

        $project;

    } @folders;

    # enrich data
    my @projects_in_page = splice(@projects, $params->{start}, $params->{limit});
    foreach my $project (@projects_in_page) {

        my $dir = $project->{base_dir};

        # git info
        if ($project->{git}) {
            my $repo = delete $project->{git}->{repo};

            # origin
            my ($origin) = grep { $_->name eq 'origin' } $repo->remotes;
            if ($origin) {
                $project->{git}{origin} = $origin->url;
                my $repo_http_url = $origin->url =~ s!git\@github\.com:(.*)\.git$!https://github.com/$1!r;
                $project->{git}{http_url} = $repo_http_url;
                $project->{git}{last_commit}{url} = "$repo_http_url/commit/$project->{git}{last_commit}{id}"
                if $project->{git}{last_commit};
            }

            # status
            # my $status = $project->{git}{status} = {};
            # my $raw_status = $repo->status({});
            # foreach my $file (keys %$raw_status) {
            #     # p $file;
            #     push(@{$status->{$_}}, $file) for @{$raw_status->{$file}{flags}}
            # }
        }

        # widgets
        my $app_config = $self->tx->app->loadConfigFile($dir->child('app.yml'));
        foreach my $widget_type (keys %{ $app_config->{widgets} || {} }) {
            my $count = keys %{$app_config->{widgets}{$widget_type}};
            $project->{widgets}{$widget_type} = $count;
        }

        # sitemap
        my $source = $app_config->{skin}
            ? $self->tx->app->loadConfigFile($dir->child("skin/$app_config->{skin}/skin.yml"))->{sitemap}
            : $app_config->{sitemap};

        if ($source) {
            my $sitemap = K1Plaza::Sitemap->from_source($source);
            $project->{sitemap}{tree} = $sitemap->page_tree;
            my $pages = $project->{sitemap}{list} = [];
            $sitemap->walk(sub { push @$pages, shift });
        }

        # registered
        my $registered = $app_instances->resultset->single({ name => $project->{name} });
        $project->{record} = { $registered->get_columns } if $registered;

    }


    # populate registered


    # return
    return {
        items => \@projects_in_page,
        total => scalar(@folders),
        start => $params->{start},
        limit => $params->{limit},
        page => $params->{page} +0,
        entries_on_this_page => scalar(@projects_in_page)
    }
}


sub load_or_register {
    my ($self, $project_name) = @_;

    # developer workspace
    my $workspace = path($self->tx->config->{developer_workspace})->to_abs;

    # find project
    my $dir = $workspace->child($project_name);
    die "Project folder '$dir' doesn't exist." unless -d $dir;

    # already registered
    my $api = $self->tx->api('AppInstance');
    my $app_instance = $api->resultset->single({ name => $project_name });
    if ($app_instance) {
        $app_instance->update({ base_dir => "$dir" });
        return { $app_instance->get_columns };
    }

    # register
    my $res = $api->register_app({ name => $project_name, base_dir => "$dir" });
    die "Error on register_app()" unless $res->{success};
    $res->{items}[0];
}


1;
