package K1Plaza::Resource::DBIC;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Try::Tiny;
use Ref::Util qw/ is_ref is_blessed_ref is_plain_hashref /;

sub _api {
    my $c = shift;

    # find resource config
    my $resource_name = $c->stash->{resource_name};
    my $resource_config = $c->stash->{resource_config};

    # p $resource_config;
    die "Missing 'resource_config' in stash" unless $resource_config;


    my $api_class = $resource_config->{api_class};

    die "Missing 'api_class' resource config for '$resource_name'"
        unless $api_class;

    delete $resource_config->{api_class};
    my $api = $c->api($api_class, $resource_config);

    # BelongsToWidget-aware
    if ($api->can('does') && $api->does('Q1::API::Widget::TraitFor::API::BelongsToWidget')) {
        my $widget_name = $c->req->query_params->param('widget');

        unless ($widget_name) {
            $c->rendered(400);
            return;
        }

        my $widget = try { $c->widget($widget_name) };

        unless ($widget_name) {
            $c->rendered(400);
            return;
        }

        $api->widget($widget);

        # HACK saving reference to widget, coz the api's widget attribute is weak_ref (see BelongsToWidget role)
        $c->stash->{'k1plaza.resource.widget'} = $widget;

    }

    $api;
}


sub list {
    my $c = shift;

    # build api
    my $api = $c->_api or return;

    # dispatch
    my $params = $c->req->query_params->to_hash;
    my $redirect = delete $params->{redirect};
    my $res = $api->list($params);

    # promise
    if (is_blessed_ref $res && $res->can('then')) {

        $res->then(sub {
            my $res = shift;
            $c->render(json => $res );
        });

        return $c->render_later;
    }

    # DBIC API
    $res = $res->result if is_blessed_ref $res && $res->can('result');
    # p $api, $res;

    $c->render(json => $res);
}


sub list_single {
    my $c = shift;

    my $api = $c->_api or return;

    my %cond = map {
        $_ eq 'app_instance_id' ? () :
        ($_ => $c->stash->{id})

    } $api->resultset->result_source->primary_columns;

    # p %cond;
    my $object = $api->find(\%cond)->first
        or return $c->reply->not_found;

    my $data = { $object->get_columns };
    my $res = $c->param('envelope')
        ? { success => \1, items => $data }
        : $data;

    $c->render(json => $res );
}


sub create {
    my $c = shift;

    # build api
    my $api = $c->_api or return;

    # create
    my $data = $c->req->json || $c->req->body_params->to_hash;
    my $res = $api->create($data);
    $res = $res->result if is_blessed_ref $res && $res->can('result');

    # promise
    if (is_blessed_ref $res && $res->can('then')) {

        $res->then(sub {
            my $res = shift;
            $c->render(json => $res );
        });

        return $c->render_later;
    }

    # redirect?
    if ($res->{success} && $c->req->query_params->param('redirect')) {

        my $id = $res->{items}[0]{id};
        my $url = $c->url_for('list_single_resource', resource_name => $c->stash('resource_name'), id => $id);
        $url->query($c->req->url->query);
        $c->res->code(303);
        return $c->redirect_to($url);
    }

    $c->render(json => $res);
}

sub update {
    my $c = shift;

    # build api
    my $api = $c->_api or return;

    # create
    my $data = $c->req->json || $c->req->body_params->to_hash;
    # $data->{id} = $c->stash->{id};
    if ($api->isa('DBIx::Class::API')) {

        foreach my $pk ($api->resultset->result_source->primary_columns) {
            next if $pk eq 'app_instance_id';
            $data->{$pk} = $c->stash->{id};
        }
    }
    else {
        $data->{id} = $c->stash->{id};
    }

    # p $data;
    my $res = $api->update($data);
    $res = $res->result if is_blessed_ref $res && $res->can('result');

    # boolean response
    unless (is_ref $res) {
        return $c->rendered($res ? 204 : 400);
    }


    # redirect?
    if (is_plain_hashref $res && $res->{success} && $c->req->query_params->param('redirect')) {

        my $id = $res->{items}[0]{id};
        my $url = $c->url_for('list_single_resource', resource_name => $c->stash('resource_name'), id => $id);
        $url->query($c->req->url->query);
        $c->res->code(303);
        return $c->redirect_to($url);
    }

    # render response
    $c->render(json => $res);
}


sub remove {
    my $c = shift;
    my $api = $c->_api or return;
    my $res = $api->delete($c->stash->{id});
    $res = $res->result if is_blessed_ref $res && $res->can('result');
    $c->rendered($res->{success} ? 204 : 400)
        if ref $res && exists $res->{success};

    $c->rendered($res ? 204 : 400);
}

1;
