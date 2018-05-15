package Q1::API::AppInstance;


use Moose;
use namespace::autoclean;
use Carp;
use Scalar::Util qw/ blessed /;
use Class::Load ();
use Mojo::File 'path';
use Mojo::Util 'slugify';
use Q1::AppInstance;
use Data::Dumper;
use Data::Printer;
use Q1::Git::Repository;

use feature qw(signatures);
no warnings qw(experimental::signatures);

extends 'DBIx::Class::API';


has '+dbic_class', default => 'AppInstance';
has '+flush_object_after_insert', default => 1;
# has '+_return_single_result', default => 1;

has '_app_base_dir', is => 'ro', isa => 'Mojo::File', lazy_build => 1;
has '_managed_app_base_dir', is => 'ro', isa => 'Mojo::File', lazy_build => 1;

has 'tx', is => 'ro', required => 1;

sub _build__managed_app_base_dir {
    my $self = shift;
	my $app = $self->tx->app;
    my $base_dir = $app->config->{managed_app_instance_base_dir} || 'managed_apps';
    return $base_dir =~ m(^/) ? path($base_dir) : $app->path_to($base_dir);
}

sub _build__app_base_dir {
    my $self = shift;
	my $app = $self->tx->app;
    my $base_dir = $app->config->{app_instance_base_dir} || 'app_instances';
    return $base_dir =~ m(^/) ? path($base_dir) : $app->path_to($base_dir);
}


around '_prepare_create_object' => sub {
    my $orig = shift;
    my $self = shift;
    my $object = shift;

    $object->{canonical_alias} ||= lc($object->{name});
    $object->{aliases} ||= [{ name => $object->{canonical_alias}, environment => $self->app->mode }];

    $object->{roles} ||= [{ rolename => 'instance_admin' }];

    $self->$orig($object);
};


sub register_app ($self, $name, $alias = undef, $env = undef) {

    my $data = ref $name ? $name : { name => $name, aliases => $alias };

	return { error => 'missing_name_param' }
		unless $data->{name};

	return { error => 'name_already_exists' }
		if $self->clone->count({ name => $data->{name} }) > 0;

    $env //= $self->app->mode;
	$data->{aliases} //= [slugify $data->{name}];
    $data->{aliases} = [$data->{aliases}] unless ref $data->{aliases} eq 'ARRAY';
	$data->{aliases} = [ map { ref eq 'HASH' ? $_ : +{ name => $_, environment => $env } } @{$data->{aliases}} ];

	return { error => 'alias_already_exists' }
		if $self->resultset->count({ 'aliases.name' => [map { $_->{name} } @{$data->{aliases}}] }, { join => 'aliases' }) > 0;

    $data->{canonical_alias} = $data->{aliases}->[0]->{name};
    # HACK use wantarray to return the object instance while not breaking compat
    my $api = $self->clone->create($data);
	wantarray
        ? $api->first->{object}
        : $api->result;
}

sub register_managed_app ($self, $params) {

    my $tx = $self->tx;

    for (qw/ name repository_url /) {
        return { error => "missing_$_" } unless $params->{$_};
    }

    # return { error => 'invalid_user' }
    #     unless blessed $params->{user} && $params->{user}->can('id');

    my %cols = (
        is_managed => 1,
		name => $params->{name},
		repository_url => $params->{repository_url}
    );

    # master repository
    my $master_repository = $self->get_master_repository($params->{repository_url}, { clone => 1})
        or return { error => 'master_repository_error' };

    # alias
    my $default_env = 'production';
    if (my $alias = $params->{alias}) {

        $alias = [$alias] unless ref $alias eq 'ARRAY';
    	$alias = [ map { ref eq 'HASH' ? $_ : +{ name => $_ } } @$alias ];

    	return { error => 'alias_already_exists' }
    		if $self->resultset->count({ 'aliases.name' => [map { $_->{name} } @$alias] }, { join => 'aliases' }) > 0;

        $cols{aliases} = $alias;
    }
    else {
        my $shared_domain = $tx->app->config->{managed_app_domain} || '';

        $shared_domain = '.'.$shared_domain
            unless $shared_domain eq '' || substr($shared_domain, 0, 1) eq '.';

        my $exists;
        my $salt = '';
        do {
            $params->{alias} = join '', lc $params->{name}, $salt, $shared_domain;
            $exists = $self->clone->find_by_alias($params->{alias});
            $salt = '-' . int(rand 9999)
                if $exists;
        }
        while ($exists);

        $cols{aliases} = [{ name => $params->{alias}, environment => $default_env }];
    }

    $cols{canonical_alias} = $cols{aliases}[0]{name};

    # create app
    # warn Dumper $params;
    my $api = $self->clone->create(\%cols);
    return { error => join(',', $api->all_errors) }
        if $api->has_errors;

    my $new_app_record = $api->first->{object};

    # create repository for main app
    my $res = $self->deploy_repository($new_app_record, $master_repository);
    return $res if $res->{error};

    return {
        success => 1,
        master_repository => $master_repository,
        deployment_repository => $res->{deployment_repository},
        app => $new_app_record
    };
}

sub get_master_repository_dir ($self, $url) {

    my ($rel_path);
    if ( $url =~ /file:\/\/.+\/([\w_.-]+(\/|$))/ ) {
        $rel_path =  $1;
    }
    elsif ( $url =~ /github.com(?:\/|:)(.*?)\.git$/ ) {
        $rel_path = $1;
    }
    else {
        die "invalid repository url '$url'";
    }

    $self->tx->app->path_to('repositories/'.$rel_path);
}

sub get_master_repository ($self, $url, $opts = {}) {

    my $repo_dir = $self->get_master_repository_dir($url);
    my $git_config = $self->tx->app->config->{git} || {};

    $self->tx->warn("Missing 'git.ssh_private_key' app config.") unless $git_config->{ssh_private_key};
    $self->tx->warn("Missing 'git.ssh_public_key' app config.") unless $git_config->{ssh_public_key};

    unless (-d $repo_dir) {
        if ($opts->{clone}) {
            return Q1::Git::Repository->clone($url, "$repo_dir", {
                bare => 1,
                ssh_private_key => $git_config->{ssh_private_key},
                ssh_public_key => $git_config->{ssh_public_key},
            });
        }
        return;
    }

    Q1::Git::Repository->new({
        git_dir => $repo_dir,
        ssh_private_key => $git_config->{ssh_private_key},
        ssh_public_key => $git_config->{ssh_public_key},
    });
}

sub get_app_repository ($self, $app) {

    my $base_dir = $self->_resolve_app_instance_dir($app);
    Q1::Git::Repository->new({ git_dir => $base_dir });
}

sub deploy_repository ($self, $app_record, $master_repository, $git_ref = 'master') {

    my $log = $self->tx->app->log;

    return { error => 'invalid_app_instance' }
        unless $app_record->is_managed;

    # resolve git ref
    unless (ref $git_ref) {
        $git_ref = ($git_ref =~ /^[0-9a-f]{40}$/)
            ? $master_repository->lookup($git_ref)
            : $master_repository->get_branch($git_ref);
    }

    die { error => 'invalid_git_reference' } unless $git_ref;

    # deployment A/B directories
    my $deployment_link = $self->_resolve_app_instance_dir($app_record);

    # resolve target repository
    my ($target_dir);

    if (-e $deployment_link) {

        die "'$deployment_link' is not a symlink! WTF???" unless -l $deployment_link;

        my $link_target = readlink $deployment_link
            or die "error reading symlink '$deployment_link': $!";

        $target_dir = $link_target eq 'production_a' ? 'production_b' : 'production_a';
    }
    else {
        $target_dir = 'production_a';
    }

    $target_dir = $deployment_link->sibling($target_dir);

    # open repo
    my $target_repo;

    if (-e $target_dir->child('.git')) {
        $target_repo= Q1::Git::Repository->new( git_dir => $target_dir );
    }
    else {
        $target_dir->make_path;
        $target_repo= Q1::Git::Repository->clone($master_repository, $target_dir );
    }

    die "error opening/cloning master repo: $target_dir" unless $target_repo;

    my $target_commit_id = $git_ref->isa('Git::Raw::Branch') ? $git_ref->target->id : $git_ref->id;

    # update repo if ref is missing
    unless ($target_repo->lookup($target_commit_id)) {
        $log->debug("Fetching master repository...");
        $target_repo->fetch;
    }

    # checkout
    $log->debug("Checking out commit $target_commit_id -> '$target_dir'");
    my $reference = $git_ref->isa('Git::Raw::Branch') ? $target_repo->get_branch($git_ref->shorthand) : $git_ref->id;
    my $res = $target_repo->checkout($reference, {
        checkout_strategy => { force => 1 },
        target_directory => "$target_dir"
    });

    # update deployment link
    if (!symlink($target_dir->basename, $deployment_link)) {
        if ($!{EEXIST}) {
            unlink($deployment_link)
                or die "Can't remove \"$deployment_link\": $!\n";
            symlink($target_dir->basename, $deployment_link)
                or die "Can't create symlink \"$deployment_link\": $!\n";
         } else {
             die "Can't create symlink \"$deployment_link\": $!\n";
         }
    }

    # update app instance
    $app_record->update({ deployment_version  => $target_commit_id });

    return {
        success => 1,
        deployment_version => $target_commit_id,
        deployment_repository => $target_repo,
    };
}


sub apply_user_acl {
	my ($self, $user) = @_;

	confess "apply_user_acl() 1st must be a user object or hashref."
	   unless $user;

	$self->add_list_filter( 'acl_users.user_id' => blessed $user ? $user->id : $user->{id} );

	$self;
}

sub find_by_uuid {
    my ($self, $uuid) = @_;
    $self->apply_user_acl($self->tx->user)->find({ uuid => $uuid })->first;
}


sub find_by_name {
	my ($self, $name) = @_;

	$self->resultset->find({ 'me.name' => $name });
}


sub find_by_alias {
	my ($self, $alias) = @_;

	$self->resultset->find(
		{ 'aliases.name' => $alias },
		{ join => 'aliases', '+select' => ['aliases.environment'], '+as' => ['environment']});
}

sub instantiate_by_id {
	my ($self, $id) = @_;

	my $obj = $self->resultset->find($id);
	return unless $obj;

	$self->_instantiate_app_instance($obj);
}

sub instantiate_by_name {
	my ($self, $name) = @_;

	my $obj = $self->find_by_name($name);
	return unless $obj;

	$self->_instantiate_app_instance($obj);
}

sub instantiate_by_alias {
	my ($self, $alias) = @_;

	my $obj = $self->find_by_alias($alias);
	return unless $obj;

	$self->_instantiate_app_instance({
		$obj->get_columns,
		current_alias => $alias
	});
}



sub _instantiate_app_instance {
    my ($self, $params) = @_;

    $params = {
        $params->get_columns,
        current_alias => $params->canonical_alias
    } if blessed $params;

    my $app = $self->app;

    # environment
	$params->{environment} ||= 'production';

    # base dir
    $params->{base_dir} = $self->_resolve_app_instance_dir($params);

    # config
	$params->{config} = $self->_load_app_instance_config($params);

    # resolve class and instantiate
    my $app_instance_class = 'Q1::AppInstance';

	$self->_mangle_app_instance_params($params);
    my $app_instance = $app_instance_class->new($params);

    # done
    $app_instance;
}

sub _resolve_app_instance_dir {
    my ($self, $params) = @_;
    $params = {$params->get_columns} if blessed $params;

    if ($params->{base_dir}) {
        return path($params->{base_dir});
    }

    if ($params->{is_managed}) {
        return $self->_managed_app_base_dir->child(substr($params->{uuid}, 0, 2), $params->{uuid}, 'production');
    }

    # legacy app
    $self->_app_base_dir->child($params->{name});

}


sub _mangle_app_instance_params { } # no-op

sub _load_app_instance_config {
	my ($self, $params) = @_;
    my $base_dir = $params->{base_dir};

    my $config_file = $base_dir->child('app.yml');

    unless (-f $config_file) {

        my $legacy_config_file = $base_dir->child('app_instance.conf');
        die "Legacy 'app_instance.conf' not supported anymore. Please update '$legacy_config_file'"
            if -f $legacy_config_file;

        return {} if $params->{is_managed};
        die sprintf("Não encontrei arquivo de configuração '%s'.\n", $config_file->to_rel($base_dir));
    }

    my ($name, $ext) = split /\./, $config_file->basename, 2;

    my $local_config_file = $config_file->sibling($name.'_local.'.$ext);

    my $app = $self->tx->app;
    -f $local_config_file
        ? $app->load_merged_config_files($local_config_file, $config_file)
        : $app->loadConfigFile($config_file);
}




1;


__END__

=pod

=head1 NAME

Q1::API::AppInstance::API

=head1 DESCRIPTION

Base class for MyAPP::API::AppInstance.

=head1 METHODS

=head2 find_by_alias

=head2 apply_user_acl

=cut
