package K1Plaza::Resource::Proxy;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Mojo::Loader qw/ load_class /;
use Scalar::Util qw/weaken/;

sub _resource {
    my $c = shift;

    # find resource config
    my $resource_name = $c->stash->{resource_name};
    my $resource_config = $c->app->config->{resources}->{$resource_name}
        || $c->app_instance->config->{resources}->{$resource_name};

    # p $resource_config;
    return unless $resource_config;

    # shallow copy
    my %config = %$resource_config;

    my $resource_class = delete $config{class} or die 'Missing "class" resource config';

    # load class
    my $app_class = ref($c->app);
    my $app_instance_name = $c->app_instance->name;
    my @classes = ("${app_class}::Resource::$resource_class");
    push @classes, "${app_class}::AppInstance::${app_instance_name}::Resource::$resource_class" unless $app_instance_name =~ /\W/;

    $resource_class = '';
    foreach my $class (@classes) {
        if (my $e = load_class $class) {
            ref $e ? die "$e" : next;
        }

        $resource_class = $class;
    }

    return unless $resource_class;
    $c->log->debug("Proxy resource '$resource_name' class '$resource_class'");
    $c->stash(resource_config => \%config);
    my $resource = $resource_class->new(%$c);
    weaken $resource->{$_} for qw(app tx);
    $resource;
}


sub list {
    my $c = shift;
    my $resource = $c->_resource or return $c->reply->not_found;
    $resource->list;
}


sub list_single {
    my $c = shift;
    my $resource = $c->_resource or return $c->reply->not_found;
    $resource->list_single;
}

sub create {
    my $c = shift;
    my $resource = $c->_resource or return $c->reply->not_found;
    $resource->create;
}

sub update {
    my $c = shift;
    my $resource = $c->_resource or return $c->reply->not_found;
    $resource->update;
}


sub remove {
    my $c = shift;
    my $resource = $c->_resource or return $c->reply->not_found;
    $resource->remove;
}

1;
