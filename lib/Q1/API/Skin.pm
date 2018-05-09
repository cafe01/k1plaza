package Q1::API::Skin;

use Moo;
use Q1::Utils::ConfigLoader;
use namespace::autoclean;
use Data::Dumper;
use JSON;
use Hash::Merge;
use Path::Class qw(dir);
use Carp;
use Scalar::Util qw/blessed/;
use Data::Printer;

has 'app' => ( is => 'ro', required => 1, weak_ref => 1 );

has 'base_skin', is => 'rw';

sub load_skin {
    my ($self, $tx, $skin_name) = @_;

    confess "load_skin(): 1st arguments must be the tx object, you gave me this: (".ref($tx).")"
        unless $tx->isa('Mojolicious::Controller');

    my $app = $self->app;
    my $app_instance = $tx->app_instance;

    $skin_name ||= $app_instance->config->{'Host'}->{$app_instance->current_alias}->{skin} ||
                   $app_instance->config->{skin} ||
                   $self->base_skin;

    unless ($skin_name) {
        return;
    }

    $app->log->debug("[Skin Manager] Loading skin '$skin_name'") if $app->_debug_skin;

    my $skin = $self->get_skin($tx, $skin_name);
    $app_instance->skin($skin);
}

sub get_skin {
    my ($self, $tx, $skin_name) = @_;

    confess "get_skin(): 1st arguments must be the tx object, you gave me this: (".ref($tx).")"
        unless blessed $tx && ($tx->isa( 'Q1::Application::Transaction') || $tx->isa( 'Mojolicious::Controller'));

    confess "get_skin(): 2nd arguments must be the skin name."
        unless defined $skin_name;

    my $app = $self->app;
    my $app_instance = $tx->app_instance;

    $app->log->debug("[Skin Manager] Loading skin '$skin_name'") if $app->_debug_skin;

    my $cache_key = $app_instance->id.":skin:$skin_name";
    my $skin = $app->cache->get($cache_key);

    unless ($skin) {
        $skin =  $self->generate_skin_config($skin_name, $app_instance);
        $app->cache->set($cache_key, $skin, '10m')
            unless $app->mode eq 'development';
    }

    $skin;
}


sub generate_skin_config {
    my ($self, $skin_name, $app_instance) = @_;

    # sanity
    confess "generate_skin_config() 2nd argument must be a app instance object, you gave me (".(ref $app_instance || $app_instance).")"
        unless blessed $app_instance && $app_instance->isa('Q1::AppInstance');

    # merge parents config
    my $merger = Hash::Merge->new;

    $merger->specify_behavior({
                        'SCALAR' => {
                                'SCALAR' => sub { $_[0] },
                                'ARRAY'  => sub { $_[0] },
                                'HASH'   => sub { $_[0] },
                        },
                        'ARRAY' => {
                                'SCALAR' => sub { [ @$_[0], $_[1] ] },
                                'ARRAY'  => sub { [ @{$_[1]}, @{$_[0]} ] },
                                'HASH'   => sub { [ @$_[0], values %{$_[1]} ] },
                        },
                        'HASH' => {
                                'SCALAR' => sub { $_[0] },
                                'ARRAY'  => sub { $_[0] },
                                'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
                        },
    });

    # read skin config
    my $skin_config = $self->_read_skin_config($skin_name, $app_instance);
    my $unmerged_skin = $merger->merge({}, $skin_config); # clone

    # parent skins
    $skin_config->{parents} = [];
    while (my $parent_skin_name  = delete $skin_config->{extend}) {

        if ($parent_skin_name eq 'base') {
            $self->app->log->warn("Ignoring deprecated skin config 'extends: base' on app ".$app_instance->name);
            next;
        }

        my $parent_skin = $self->_read_skin_config($parent_skin_name, $app_instance);

        # ignore if empty or parent is the base_skin (old spec, now the base is applied automaticaly)
        next if !(defined $parent_skin && length $parent_skin) || $parent_skin eq $self->base_skin;

        # save parent skin name
        push @{$skin_config->{parents}}, [$parent_skin_name, $parent_skin->{is_shared}];

        # merge with parent config
        $skin_config = $merger->merge( $skin_config, $parent_skin );

    }

    # merge base skin
    $skin_config = $merger->merge( $skin_config, $self->base_skin )
        if $self->base_skin && $self->base_skin ne $skin_name;

    # save unmerged
    $skin_config->{_unmerged} = $unmerged_skin;

    # return config
    $skin_config;

}



sub _read_skin_config {
    my ($self, $skin_name, $app_instance) = @_;
    my $app = $self->app;

    # managed app
    # if ($app_instance->is_managed) {
    #     $app->log->debug("Generating managed skin config for skin '$skin_name'") if $app->_debug_skin;
    #     return $skin_name eq 'base' ? { name => $skin_name, template_engine => 'Plift' }
    #                                 : { name => $skin_name, extend => 'base' }
    # }

    # find skin.conf or skin.yml
    my ($config_file, $is_shared_skin, @skin_search_path);
    my $app_skin_dir = $app_instance->path_to('skin');
    my $shared_skin_dir = $app->path_to('share/skin');

    foreach my $filename (qw/ skin.yml skin.conf /) {

        # app skin
        my $file = $app_skin_dir->child($skin_name, $filename);
        push @skin_search_path, $file;
        if (-f $file) {
            $config_file = $file;
            last;
        }

        # shared skin
        $file = $shared_skin_dir->child($skin_name, $filename);
        push @skin_search_path, $file;
        if (-f $file) {
            $config_file = $file;
            $is_shared_skin = 1;
            last;
        }
    }

    # not found
    die sprintf("Couldn't find the skin.conf file for the skin named '%s'. Searched at:\n%s", $skin_name, join "\n", @skin_search_path)
       unless $config_file;

    # read
    $app->log->debug("Reading skin.conf for '$skin_name' at '$config_file'")
       if $app->_debug_skin;

    my $skin = Q1::Utils::ConfigLoader->loadConfigFile("$config_file");
    $skin->{is_shared} = 1 if $is_shared_skin;
    $skin;
}



sub generate_template_include_path {
    my ($self, $tx) = @_;

    confess "generate_template_include_path(): 1st arguments must be the tx object, you gave me this: (".ref($tx).")"
        unless blessed $tx && ($tx->isa( 'Q1::Application::Transaction') || $tx->isa( 'Mojolicious::Controller'));

    return [
        # $tx->app_instance->path_to('template'),
        @{ $self->generate_skin_paths($tx, 'template') },
        $tx->app_instance->path_to('pages')
    ]
}

sub generate_javascript_search_path {
    my ($self, $tx) = @_;

    confess "generate_javascript_search_path(): 1st arguments must be the tx object, you gave me this: (".ref($tx).")"
        unless blessed $tx && ($tx->isa( 'Q1::Application::Transaction') || $tx->isa( 'Mojolicious::Controller'));

    $self->generate_skin_paths($tx, 'snippet');
}

sub generate_static_search_path {
    my ($self, $tx) = @_;

    confess "generate_static_search_path(): 1st arguments must be the tx object, you gave me this: (".ref($tx).")"
        unless blessed $tx && ($tx->isa( 'Q1::Application::Transaction') || $tx->isa( 'Mojolicious::Controller'));

    $self->generate_skin_paths($tx, 'static');
}

sub generate_skin_paths {
    my ($self, $tx, $suffix) = @_;

    return [] unless $tx->has_app_instance;

    my $app_instance = $tx->app_instance;
    my $skin = $app_instance->skin;
    my @paths;

    if ($skin) {
        # one path for each skin
        foreach my $skin_name ($skin->{name}, map { $_->{name} } @{$skin->{parents}||[]}) {
            push @paths, $app_instance->base_dir->child('skin', $skin_name, $suffix)->to_string;
        }
    }
    else {
        # no skin,  single path
        push @paths, $app_instance->base_dir->child($suffix)->to_string;
    }

    \@paths;
}


sub find_skin_static_file {
    my ($self, $tx, $filepath) = @_;

    # sanity
    confess "find_skin_static_file(): 1st arguments must be a tx object, you gave me (".(ref $tx || $tx).")"
        unless ref $tx eq 'Q1::Web::Transaction';

    my $app = $self->app;
    my $app_instance = $tx->app_instance;

    # remove trailing slash (no absolute path)
    $filepath = substr($filepath, 1) if substr($filepath, 0, 1) eq '/';
    return if $filepath eq '';

    # path with scope
    if ($filepath =~ m!^(front|mobile|back)/(.*)!) {

        $tx->log->debug(sprintf "[app: %s] find_skin_static_file() found file with scope: %s", $app_instance->name, $filepath);
        $filepath = $2;
    }

    # search path
    my $search_path = $self->generate_static_search_path($tx);

    # search
    foreach my $dir (@$search_path) {
        my $file = $dir->child($filepath);
        $app->log->debug("[Skin] Searching static file: $file") if $app->_debug_skin;
        return $file if $file->is_file;
    }

    # not found
    return undef;
}


1;


__END__

=pod

=head1 NAME

Q1::Application::Feature::Web::Skin::Manager - well, it manages skins.

=head1 DESCRIPTION

Does all things related to skin.

=head1 METHODS

=head2 load_skin($tx, $skin_name?)

=head2 generate_skin_config( $skin_name )

Generates the final skin configuration by merging the config (aka: skin.conf) of skin $skin_name with the config of its parent(s).

NOTE: the array merging behavior got modified so the content of parent skins comes first in the array. (needed for the resources inheritance logic)

=cut
