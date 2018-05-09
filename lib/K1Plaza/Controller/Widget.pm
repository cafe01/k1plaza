package K1Plaza::Controller::Widget;
use Mojo::Base 'Mojolicious::Controller';
use Ref::Util qw/ is_blessed_ref is_plain_hashref is_plain_scalarref /;
use Data::Printer;

sub _get_widget {
    my ($c) = @_;
    return unless $c->stash->{widget_name};
    $c->widget($c->stash->{widget_name}, undef, undef, $c->req->query_params->to_hash);
}



sub list {
    my $c = shift;

    # get widget
    my $widget = $c->_get_widget or return $c->reply->not_found;

    $c->render(json => $widget->data);
}

sub list_single {
    my $c = shift;

    # get widget
    my $widget = $c->_get_widget;
    return $c->reply->not_found unless $widget and $widget->can('fetch_resource');
    my $resource = $widget->fetch_resource($c->stash->{id})
        or return $c->reply->not_found;

    my $res = $c->param('envelope') ? { success => 1, items => $resource} : $resource;
    $c->render(json => $res);
}

sub update {
    my $c = shift;

    # get widget
    my $widget = $c->_get_widget;
    return $c->reply->not_found unless $widget and $widget->can('fetch_resource');
    my $resource = $widget->fetch_resource($c->stash->{id})
        or return $c->reply->not_found;

    my $data = $c->req->json || $c->req->body_params->to_hash;
    my $res = $widget->update_resource(undef, $c->stash->{id}, $resource, $data);


    if (is_plain_scalarref $res) {
        $c->rendered($$res);
    }
    elsif (is_plain_hashref $res) {
        $c->rendered($res->{success} ? 204 : 400);
    }
    else {
        $c->rendered($res ? 204 : 400);
    }
}

sub remove {
    my $c = shift;

    # get widget
    my $widget = $c->_get_widget;
    return $c->reply->not_found unless $widget and $widget->can('fetch_resource');
    my $resource = $widget->fetch_resource($c->stash->{id})
        or return $c->reply->not_found;

    my $data = $c->req->json || $c->req->body_params->to_hash;
    my $res = $widget->delete_resource(undef, $c->stash->{id});
    $res = $$res if is_plain_scalarref $res;
    $c->rendered($res ? 204 : 400);
}


sub widget_action {
    my ($c) = @_;
    my $log = $c->app->log;
    my $widget = $c->_get_widget or return $c->reply->not_found;

    # not default action
    my $action_name = $c->stash->{widget_action};
    unless ($c->stash->{widget_action} eq 'create_resource') {

        my $path = $c->stash->{widget_action}
            or return $c->reply->not_found;

        # widget action
        my $match;
        return $c->reply->not_found unless
            $match = $widget->path_router->match($path, method => $c->req->method)
            and $match->arguments
            and $match->arguments->{widget_action};

        $action_name = $match->arguments->{widget_action};
        $widget->set_arguments($match->captures);
    }

    # set params
    $widget->set_parameters($c->req->query_params->to_hash);

    # run
    my $action = $widget->can($action_name);
    unless ($action) {
        return $c->reply->exception("No method '$action_name' on widget '".$widget->name."'");
    }

    # run
    $log->debug(sprintf "Running widget action: %s->%s", $widget->name, $action_name);
    my $data = $c->req->json || $c->req->body_params->to_hash;
    my $res = $widget->$action($data);
    # p $res;

    # json response
    if (is_plain_hashref $res) {
        return $c->render(json => $res);
    }

    # redirect response
    if (is_blessed_ref $res && $res->isa('URI')) {
        $log->debug("Widget action URI response: $res");
        my $id = [split '/', $res->path]->[-1];
        $log->debug("list_single_widget route: ".$c->app->routes->lookup('list_single_widget'));

        my $url = $c->url_for('list_single_widget', widget_name => $widget->name, id => $id);
        $url->query($c->req->url->query);
        $c->res->code(303);
        return $c->redirect_to($url);
    }

    # 201 Created / 204 No Content
    $log->debug("Sending generic response.");
    $c->rendered($c->req->method eq 'POST' ? 201 : 204);
}




1;
