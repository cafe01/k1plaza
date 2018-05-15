package K1Plaza::Controller::RenderPage;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Mojo::Util qw/camelize/;
use Scalar::Util qw/weaken/;
use Mojo::Loader qw/load_class/;


sub default {
    my $c = shift;
    my $log = $c->app->log;

    # p $c->match->stack;
    my $page_config = $c->match->stack->[-1];

    # redirect
    return $c->redirect_to($page_config->{redirect})
        if $page_config->{redirect};

    # check_user_role
    return $c->redirect_to_login(continue => 1)
        if $page_config->{check_user_role} && !($c->user_exists && $c->user->check_roles($page_config->{check_user_role}));

    # dispatch controller
    if ($page_config->{controller} && $page_config->{controller} ne 'render_page') {
        my $controller = $c->_load_app_instance_controller($page_config->{controller});
        my $action = $page_config->{action} || 'process';
        return $controller->$action();
    }

    # update stash
    $page_config->{template} ||= "page/$page_config->{fullpath}";
    $c->stash(%$page_config);

    # widget hook
    my $widget_name = $page_config->{widget_args} || $page_config->{widget};
    if ($widget_name) {

        my $widget = $c->widget($widget_name);

        if ( $widget->can('before_render_page') ) {
            $widget->before_render_page($c);
            return if $c->res->code;
        }
    }

    # page property
    $c->properties->set("page." . $page_config->{fullpath} =~ s/\//./gr);

    # vivify helpers
    $c->$_ for qw/ captures reply find_template_file locale uri_for_media site_url_for /;
    $c->uri_for_static('');
    $c->widget;

    # render
    $c->log->info(sprintf "⤷ /%s '%s' (%s)", $page_config->{fullpath}, $page_config->{title} || $page_config->{fullpath}, $page_config->{template});
    $c->render(handler => 'plift');
}

sub _load_app_instance_controller {
    my ($c, $controller_name) = @_;
    my $controller_class = join '::', ref($c->app), 'AppInstance', $c->app_instance->name, 'Controller', camelize($controller_name);

    if (my $e = load_class $controller_class) {
        die ref $e ? "Exception: $e" : "Can't find controller class '$controller_class'";
    }

    my $controller = $controller_class->new(%$c);
    weaken $controller->{$_} for qw(app tx);
    $controller;

}


1;
