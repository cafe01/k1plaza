package K1Plaza::Resource::Expo;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;


sub _api {
    my $c = shift;
    my $name = $c->stash('expo_name');
    # TODO return 404 if blog doesnt exist
    $c->api('Expo', { widget => $c->widget($name) });
}


sub list {
    my $c = shift;
    my $api = $c->_api or return;

    my $data = $api->list($c->req->params->to_hash)->result;
    $c->render(json => $data);
}


sub list_single {
    my $c = shift;
    my $api = $c->_api or return;
    my $res = $api->find($c->stash->{id})->result;
    $c->render(json => $res);
}


sub create {
    my $c = shift;
    my $api = $c->_api or return;

    # create
    my $res = $api->create($c->req->json)->result;

    # error
    $res->{success} = ${$res->{success}} if ref $res->{success};
    unless ($res->{success}) {
        $c->res->code(400);
        return $c->render(json => $res);
    }

    # redirect
    my $uri = $c->req->url->clone;
    $uri->path->trailing_slash(1)->merge($res->{items}[0]->{id});
    $c->res->code(303); # See Other
    $c->redirect_to($uri->path_query);
}


sub update {
    my $c = shift;
    my $api = $c->_api or return;

    my $object = $api->find($c->stash->{id})->first
        or return $c->reply->not_found;

    my $data = $c->req->json;
    $data->{id} = $c->stash->{id};

    my $res = $api->update($data)->result;
    $c->render( json => $res );
}

sub reposition {
    my $c = shift;
    my $api = $c->_api or return;
    my $data = $c->req->json;
    $api->reposition($data->{from}, $data->{to});
    $c->rendered(204);
}

sub remove {
    my $c = shift;
    my $api = $c->_api or return;
    my $res = $api->delete($c->stash->{id})->result;
    $c->res->code($res->{success} ? 204 : 400);
    $c->render(json => $res);
}

1;
