package K1Plaza::Apis;
use Mojo::Base '-base';
use Mojo::Loader qw/load_class/;
use Carp qw/ confess /;

use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);


has 'namespaces' => sub {[__PACKAGE__.'::API']};


sub load_api ($self, $c, $name, $params = {})  {


    my $api_class;
    my $app_instance = $c->stash->{__app_instance};

    my @namespaces = $self->namespaces->@*;
    unshift(@namespaces, 'K1Plaza::AppInstance::'.$app_instance->name.'::API')
        if $app_instance && $app_instance->name !~ /\W/;

    foreach my $ns (@namespaces) {

        my $class = $ns."::$name";
        if (my $e = load_class $class) {
            die $e if ref $e;
        }
        else {
            $api_class = $class;
            last;
        }
    }

    confess "Unknown API '$name'" unless $api_class;

    $api_class->new(
        $app_instance ? (app_instance_id => $app_instance->id) : (),
        %$params,
        log => $c->app->log,
        app => $c->app,
        c => $c,
        tx => $c,
    );
}












1;
