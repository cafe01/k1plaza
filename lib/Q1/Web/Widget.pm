package Q1::Web::Widget;

use utf8;
use Q1::Moose::Widget;
use namespace::autoclean;
use Data::Dumper;
use Carp qw/ confess /;
use Digest::MurmurHash qw(murmur_hash);
use constant DEBUG_WIDGET => $ENV{DEBUG_WIDGET};

# TODO create has_cache_param (or has_cache_vary)


# attributes
has 'name'      => ( is => 'ro', isa => 'Str', required => 1 );

sub app { shift->tx->app }
has 'tx'        => ( is => 'ro', isa => 'Object', weak_ref => 1 );

has 'data'      => ( is => 'rw', isa => 'Any', clearer => '_clear_data', lazy_build => 1 );
has 'db_object' => ( is => 'ro', isa => 'Q1::API::Widget::Schema::Result::Widget', handles => [qw/ id version /] );
has 'renderer'  => ( is => 'ro', isa => 'CodeRef' );
has 'is_ephemeral', is => 'ro', isa => 'Bool', default => 0;


has 'config' => (
    is => 'ro',
    lazy => 1,
    init_arg => undef,
    default => sub {
        my ($self) = @_;
        +{
            map {
                my $predicate = $self->can("has_$_");
                $self->$predicate ? ($_ => $self->$_) : ();
            } @{ $self->meta->config_list }
        }
    }
);

has 'arguments' => (
    is => 'ro',
    lazy => 1,
    init_arg => undef,
    clearer => '_clear_arguments',
    default => sub {
        my ($self) = @_;
        +{
            map {
                my $predicate = $self->can("has_$_");
                $self->$predicate ? ($_ => $self->$_) : ();
            } @{ $self->meta->argument_list }
        }
    }
);


has 'parameters' => (
    is => 'ro',
    lazy => 1,
    init_arg => undef,
    clearer => '_clear_parameters',
    default => sub {
        my ($self) = @_;
        +{
            map {
                my $predicate = $self->can("has_$_");
                $self->$predicate ? ($_ => $self->$_) : ();
            } @{ $self->meta->parameter_list }
        }
    }
);


has 'template'  => ( is => 'ro', isa => 'Str' );
#has 'params'    => ( is => 'rw', isa => 'HashRef', predicate => 'has_params' );



# config attributes
has_config 'title'      => ( isa => 'Str' );
has_config 'menu_group' => ( isa => 'Str' );

has_config 'view'      => ( isa => 'Str' );
has_config 'view_args' => ( isa => 'HashRef', default => sub{ {} } );

has_config 'backend_view'        => ( isa => 'Str' );
has_config 'backend_view_config' => ( isa => 'HashRef', default => sub{ {} } );

has_config 'metadata', isa => 'HashRef';

has_config 'cache_duration', is => 'rw', isa => 'Str', default => '1d';


 sub BUILDARGS {
    my ($class, $init_args, $config, $args, $params) = @_;

    confess 'Q1::Web::Widget->new(\%init_args?, \%config?, \%arguments?, \%params)'
        unless ref $init_args eq 'HASH';

    # new(\%init_args?, \%config?, \%arguments?, \%params)
    # init_args: must come from trusted source, will be accepted as-is
    # config: accepted if  was declared with 'is_config'
    # arguments: only accepted if attribute was declared with 'is_argument'
    # params: only accepted if attribute was declared with 'is_parameter'

    foreach my $attr ($class->meta->get_all_attributes) {
        my $init_arg = $attr->init_arg;
        next unless defined $init_arg;

        # config
        $init_args->{$init_arg} = $config->{$init_arg}
            if $config && exists $config->{$init_arg} && $attr->can('is_config') && $attr->is_config;

        # argument
        $init_args->{$init_arg} = $args->{$init_arg}
            if $args && exists $args->{$init_arg} && $attr->can('is_argument') && $attr->is_argument;

        # parameter
        $init_args->{$init_arg} = $params->{$init_arg}
            if $params && exists $params->{$init_arg} && $attr->can('is_parameter') && $attr->is_parameter;

    }

    $init_args;
}


sub _build_data {
    my ($self) = @_;

    return $self->get_data($self->tx, $self->arguments, $self->parameters)
        unless $self->cache_duration;

    my $key = 'widgetdata:'.murmur_hash($self->_cache_key);
    my $tx = $self->tx;
    my $cache = $tx->app->cache;
    my $log = $tx->log;

    my $data = $cache->get($key);

    unless ($data) {
        $log->debug("CACHE MISS for widget '".($self->name || ref($self))."' $key")
            if DEBUG_WIDGET;

        $data = $self->get_data($self->tx, $self->arguments, $self->parameters);

        $log->debug(sprintf "Caching '%s' data (%s) for %s", $self->name || ref($self), $data, $self->cache_duration)
            if DEBUG_WIDGET;
        $cache->set($key, $data, $self->cache_duration);
    }


    $data;
}

sub get_data {} # no-op


sub _cache_key {
    my ($self) = @_;

    my $config = $self->config;
    my $arguments = $self->arguments;
    my $parameters = $self->parameters;

    my %keys = map { $_ => 1 }
        @{$self->meta->config_list},
        @{$self->meta->argument_list},
        @{$self->meta->parameter_list};

    my $cache_key = join( ':',
        'app',
        $self->tx->has_app_instance ? $self->tx->app_instance->id : '-',
        'widget',
        ref($self),
        $self->is_ephemeral ? () : ($self->db_object->id, 'version', $self->db_object->version),

        (map {
            my $value = $self->$_;
            $value = '' unless defined $value;
            ref $value ? () :($_ => $value)

        } sort keys %keys),
    );

    return $self->_mangle_cache_key($cache_key)
        if $self->can('_mangle_cache_key');

    $cache_key;
}


sub bump_version {
    my ($self) = @_;
    return if $self->is_ephemeral;
    $self->db_object->bump_version;
    $self->db_object->discard_changes;
}



sub initialize {
    shift->db_object->update({ is_initialized => 1 });
}


# no-op
sub load_fixtures {}


sub _load_template {
    my ($self, $tpl_name) = @_;

    # strip deprecated .html suffix
    $tpl_name =~ s/\.html$//;

    my $file = $self->tx->find_template_file($tpl_name);

    die sprintf "[%s] can't find template: %s\n", ref $self, $tpl_name
        unless defined $file;

    my $handle = $file->open('<:encoding(UTF-8)');
    my $ret = my $html_source = '';
    while ($ret = $handle->read(my $buffer, 131072, 0)) { $html_source .= $buffer }
    die qq{Can't read from file "$file": $!} unless defined $ret;

    $html_source;
}

sub _load_element_template {
    my ($self, $element) = @_;
    return unless $element->children->size == 0;

    $element->html($self->_load_template($self->template));
    $element;
}



sub set_arguments {
    my ($self, $args) = @_;
    return unless $args;
    my $meta = $self->meta;

    foreach my $attr_name ( keys %$args ) {
        my $attr = $meta->find_attribute_by_name($attr_name);
        next unless $attr && $attr->can('is_argument') && $attr->is_argument;
        my $accessor = $attr->accessor;
        $self->$accessor($args->{$attr_name});
    }

    $self->_clear_arguments;
}


sub set_parameters {
    my ($self, $args) = @_;
    return unless $args;
    my $meta = $self->meta;

    foreach my $attr_name ( keys %$args ) {
        my $attr = $meta->find_attribute_by_name($attr_name);
        next unless $attr && $attr->can('is_parameter') && $attr->is_parameter;
        my $accessor = $attr->accessor;
        $self->$accessor($args->{$attr_name});
    }

    $self->_clear_parameters;
}










__PACKAGE__->meta->make_immutable();



1;


__END__

=pod

=head1 NAME

Q1::Web::Widget

=head1 DESCRIPTION

=head1 METHODS

=head2 initialize

Perform any initialization needed here.

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
