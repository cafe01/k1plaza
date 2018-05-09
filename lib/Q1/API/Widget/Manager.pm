package Q1::API::Widget::Manager;

use utf8;
use Moo;
use namespace::autoclean;
use Try::Tiny;
use Carp qw/ confess /;
use Scalar::Util qw/blessed/;

has 'app' => ( is => 'ro', required => 1, weak_ref => 1 );


sub get_widget_by_name {
    my ($self, $tx, $name, $extra_config, $args, $params) = @_;

    confess "get_widget_by_name(): no widget name supplied!"
        unless $name;

    confess "get_widget_by_name() 1st argument must be the tx object!"
        unless blessed($tx) && ($tx->isa('Q1::Application::Transaction') || $tx->isa('Mojolicious::Controller'));

    # find widget config
    my ($config, $widget_type);
    my $widgets_spec = $tx->has_app_instance ? $tx->app_instance->config->{widgets} : {};

    OUTER:
    foreach my $type (keys %$widgets_spec) {
        foreach my $widget_name (keys %{$widgets_spec->{$type}}) {
            if ($name eq $widget_name) {
                $config = $widgets_spec->{$type}->{$widget_name};
                $widget_type = $type;
                last OUTER;
            }
        }
    }

    # didnt find config, try to instantiate by type
    unless ($config) {
        return $self->_instantiate_by_type($tx, $name, $extra_config, $args, $params);
    }

    # config says its ephemeral
    if ($config->{is_ephemeral}) {

        $config->{__name} = $name;
        return $self->_instantiate_by_type($tx, $widget_type, $extra_config ? { %$config, %$extra_config } : $config, $args, $params);
    }

    # get from db (install if 1st time)
    # my $db_obj  = $tx->api('Widget')->find({ name => $name })->first;
    #
    # return $self->_instantiate_widget($tx, $db_obj, $extra_config ? { %$config, %$extra_config } : $config, $args, $params)
    #     if $db_obj;

    my $db_obj = $tx->{'widget_cache'}->{$name} || $tx->api('Widget')->find({ name => $name })->first;

    if ($db_obj) {
        $tx->{'widget_cache'}->{$name} = $db_obj;
        return $self->_instantiate_widget($tx, $db_obj, $extra_config ? { %$config, %$extra_config } : $config, $args, $params)
    }

    # auto-install
    return $self->_install_widget($tx, $name, $widget_type, $extra_config ? { %$config, %$extra_config } : $config, $args, $params);
}


sub _instantiate_by_type {
    my ($self, $tx, $type, $config, $args, $params) = @_;

    # resolve class
    my $widget_class = $self->_resolve_widget_class($tx, $type);

    # init args
    my $init_args = {
        name        => delete($config->{__name}) || $type,
        app         => $self->app,
        tx          => $tx
    };

    # instantiate
    my $error;
    my $widget = try { $widget_class->new($init_args, $config, $args, $params) }
                 catch { $error = $_ };

    die({ message => "Error instantiating widget '$widget_class': $error" })
        if $error;

    # error: not ephemeral!
    die({ message => "Can't instantiate widget by type '$type' ($widget_class). Only ephemeral widgets can be created by type!" })
        unless $widget->is_ephemeral;

    $widget;
}


sub _instantiate_widget {
    my ($self, $tx, $db_obj, $config, $args, $params) = @_;
    my $app = $self->app;

    # init_args
    my $init_args = {
        name        => $db_obj->name,
        app         => $app,
        db_object   => $db_obj,
        tx          => $tx,
    };

    # instantiate
    my $widget_class = $db_obj->class;
    Class::Load::load_class($widget_class);
    my $widget = $widget_class->new($init_args, $config, $args, $params);

    # initialize
    unless ($db_obj->is_initialized) {
        $widget->initialize;
    }

    $widget;
}


sub _install_widget {
	my ($self, $tx, $widget_name, $widget_type, $config, $args, $params) = @_;

    my $app = $self->app;
    my $api = $tx->api('Widget');

    # find existing widget
    my $cols = { name => lc $widget_name };
    my $widget_db = $api->find($cols)->first;

    unless ($widget_db) {

        $cols->{class} = $self->_resolve_widget_class($tx, $widget_type)
            || die "Can't resolve class for widget '$cols->{name}' from type '$widget_type'";

        $widget_db = $api->create($cols)->first->{object};
        $widget_db->discard_changes;
    }

    # instantiate
    # TODO: deny widget to change the type? eg. a Gallery become a Blog, forgotten data would be left behind
    my $widget = $self->_instantiate_widget($tx, $widget_db, $config, $args, $params);

    $widget;
}


sub _resolve_widget_class {
    my ($self, $tx, $widget_type) = @_;
    my $app_class = ref($self->app);

    my @try_classes = (
        $app_class.'::Widget::'.$widget_type,
        'Q1::Web::Widget::'.$widget_type
    );

    if ($tx->has_app_instance && $tx->app_instance->name !~ /\W/) {
        unshift @try_classes, $app_class.'::AppInstance::'.$tx->app_instance->name.'::Widget::'.$widget_type;
    }

    my $error;
    my $class = Class::Load::load_first_existing_class(@try_classes);

    $class;
}



1;


__END__

=pod

=head1 NAME

Q1::API::Widget::Manager

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
