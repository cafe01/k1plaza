package K1Plaza::Resource::Blog;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;


sub _api {
    my $c = shift;
    my $name = $c->stash('blog_name');
    # TODO return 404 if blog doesnt exist
    $c->api('Blog', { widget => $c->widget($name) });
}


sub list {
    my $c = shift;
    my $api = $c->_api or return;

    # prepare api
    $api = $api->with_related('author', undef, 1)
               ->with_related('categories', undef, 1)
               ->with_related('tags', undef, 1)
               ->with_url
               ->page($c->param('page') || 1)
               ->limit($c->param('limit') || 10);


    # hide unpublished
    $api->add_list_filter( is_published => 1 ) unless $c->param('include_unpublished');

    my $data = $api->list->result;

    # author_name
    foreach my $post (@{ $data->{items} }) {
        next unless $post->{author};
        $post->{author_name} = $post->{author}{first_name};
        $post->{author_name} .= " $post->{author}{last_name}"
            if defined $post->{author}{last_name} && length $post->{author}{last_name};
    }

    $c->render(json => $data);
}


sub list_single {
    my $c = shift;
    my $res = $c->_api->find($c->stash->{id})->result;
    $c->render(json => $res);
}


sub create {
    my $c = shift;

    # create
    my $res = $c->_api->create($c->req->json)->result;

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
    my $api = $c->_api;

    my $object = $api->find($c->stash->{id})->first
        or return $c->reply->not_found;

    my $data = $c->req->json;
    $data->{id} = $c->stash->{id};

    my $res = $api->update($data)->result;
    $c->render( json => $res );
}


sub remove {
    my $c = shift;
    my $res = $c->_api->delete($c->stash->{id})->result;
    $c->res->code($res->{success} ? 204 : 400);
    $c->render(json => $res);
}

1;
