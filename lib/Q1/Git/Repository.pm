package Q1::Git::Repository;

use Data::Dumper;
use Data::Printer;
use Moo;
use namespace::autoclean;
use Git::Raw;
use Try::Tiny;

use feature qw(signatures);
no warnings qw(experimental::signatures);

has 'git_dir',  is => 'ro', required => 1;

has 'developer_name',  is => 'ro';
has 'developer_email',  is => 'ro';
has 'uuid',  is => 'ro';

has 'work_dir', is => 'ro', lazy => 1, default => sub { shift->git_dir };

has 'ssh_private_key', is => 'rw';
has 'ssh_public_key', is => 'rw';

has 'raw',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $repo = try { Git::Raw::Repository->open($self->git_dir) };
        if (!$repo) {
            my $is_bare = $self->git_dir ne $self->work_dir;
            $repo = Git::Raw::Repository->init($self->git_dir, $is_bare);
        }
        die "Could not init/open git repository at: ".$self->git_dir
            unless $repo;

        $repo;
    },
    handles => [qw/ is_bare is_empty head lookup remotes /];


sub BUILD {
    # init or open
    shift->raw;
}


sub _build_credentials_callback {
    my ($opts) = @_;


    # Github access token - https://blog.github.com/2012-09-21-easier-builds-and-deployments-using-git-over-https-and-oauth/
    return sub {
        my ($url, $user, $types) = @_;

        Git::Raw::Cred->userpass($opts->{github_access_token}, 'x-oauth-basic');

    } if $opts->{github_access_token};

    # ssh keys
    return sub {
        my ($url, $user, $types) = @_;
        warn "# on github credential callback ($url, $user)\n";
        p $types;
        
        die "Host $url does not support ssh_key credential. (@$types)"
            unless grep { 'ssh_key' } @$types;

        $opts->{ssh_public_key} ||= "$opts->{ssh_private_key}.pub";
        Git::Raw::Cred->sshkey($user, $opts->{ssh_public_key}, $opts->{ssh_private_key});
        
    } if $opts->{ssh_private_key};

    # no creds
    die "¯\_(ツ)_/¯";
}



sub clone {
    my ($class, $url, $target_dir, $opts, $fetch_opts, $checkout_opts) = @_;
    $opts ||= {};
    $fetch_opts ||= {};
    $checkout_opts ||= {};

    my $private_key = $opts->{ssh_private_key};
    my $public_key = $opts->{ssh_public_key};


    for (qw/transfer_progress sideband_progress/) {
        $fetch_opts->{callbacks}{$_} = $opts->{$_}
            if $opts->{$_};
    }

    $fetch_opts->{callbacks}{credentials} = _build_credentials_callback($opts)
        if ($opts->{github_access_token} || $opts->{ssh_private_key});

    if (ref $url && $url->isa(__PACKAGE__)) {
        $url = 'file://'.$url->git_dir;
    }

    # p $fetch_opts;
    my $raw = Git::Raw::Repository->clone($url, $target_dir, $opts, $fetch_opts, $checkout_opts);

    $class->new({
        # raw => $raw,
        git_dir => $target_dir,
        ssh_private_key => $private_key,
        ssh_public_key => $public_key,
        github_access_token => $opts->{github_access_token}
    });
}



sub path_to ($self, $subpath) {
    my $workdir = $self->work_dir;
    my $path = $workdir->child($subpath)->realpath;

    return unless $workdir->subsumes($path);
    $path;
}


sub commit ($self, $message, $opts = {}) {

    my $raw = $self->raw;

    my $dev_name = $self->developer_name;
    my $dev_email = $self->developer_email;
    my $index = $raw->index;

    return { error => 'missing_developer_name' } unless $self->developer_name;
    return { error => 'missing_developer_email' } unless $self->developer_email;
    return { error => 'invalid_repository_state' } unless $raw->state eq 'none';

    if ($opts->{add_all}) {
        $index->add_all({ paths => ['*']});
        $index->write;
    }

    my @entries = $index->entries;
    return { error => 'empty_index' } unless scalar(@entries) > 0;

    my $signature = Git::Raw::Signature->now($dev_name, $dev_email);
    my $error;
    my $commit = try {
        $raw->commit($message, $signature, $signature, [$raw->is_empty ? () : $raw->head->target ], $index->write_tree);
    } catch { $error = $_ };

    return { error => $error } if $error;

    $index->clear;
    $commit;
}


sub branch ($self, $name) {
    my $raw = $self->raw;
    return { error => 'already_exists' } if $self->get_branch($name);
    return { error => 'empty_repository' } if $raw->is_empty;

    $raw->branch($name, $raw->head->target);
}


sub get_branch ($self, $name, $is_local = 1) {
    Git::Raw::Branch->lookup($self->raw, $name, $is_local);
}

sub checkout ($self, $ref, $opts = {}) {
    $opts->{checkout_strategy} ||= { force => 1 };

    my $raw = $self->raw;
    return { error => 'invalid_repository_state' } unless $raw->state eq 'none';

    $ref = $raw->lookup($ref) unless ref $ref;
    $raw->checkout($ref->can('target') ? $ref->target : $ref, $opts);
    if ($ref->isa('Git::Raw::Branch')) {
        $raw->head($ref)
    } else {
        $raw->detach_head($ref);
    }

    return { success => 1 };
}

sub branch_info ($self) {

    my $head = $self->head;

    +{
        name => $head->shorthand,
        commit_id => $head->target->id,
    }
}

sub fetch ($self, $remote_name = 'origin') {
    my $raw = $self->raw;

    my ($remote) = grep { $_->name eq $remote_name } $raw->remotes;
    die "No remote '$remote_name' found." unless $remote;
    
    # fetch
    my $fetch_opts = {};
    $fetch_opts->{callbacks}->{credentials} = _build_credentials_callback({
        ssh_private_key => $self->ssh_private_key, 
        ssh_public_key  => $self->ssh_public_key
    }) if $self->ssh_private_key;

    $remote->fetch($fetch_opts);

    # remote track
    foreach my $branch ($raw->branches('local')) {
        if (my $remote_branch = $self->get_branch("$remote_name/".$branch->shorthand, 0)) {
            $branch->target($remote_branch->target);
        }
    }
}

sub log {
    # body...
}

sub branches {

}

sub function_name {
    # body...
}








1;
