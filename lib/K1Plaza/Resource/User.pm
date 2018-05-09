package K1Plaza::Resource::User;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

sub list {
    my $c = shift;

    my $res = $c->api('User')->with_icon
                             ->with_related('roles')
                             ->list($c->req->query_params->to_hash)
                             ->result;

    $c->render(json => $res);
}

sub list_single {
    my $c = shift;
    my $id = $c->stash->{id};

    $id = $c->user->id if $id eq 'me';
    my $record = $c->api('User')->find({ id => $id })->first;

    return $c->reply->not_found unless $record;

    my $data = $record->as_hashref;
    $data->{icon} = $record->icon;
    $data->{roles} = [map { +{ $_->get_columns } } $record->roles];

    $data = { items => $data } if $c->req->param('envelope');
    $c->render(json => $data);
}

sub create {
    my $c = shift;
    my $req = $c->req;
    my $data = $req->json;
    my %cols = map { $_ => $data->{$_} || '' } qw/ first_name last_name email /;

    my $res = $c->api('User')->create(\%cols)->result;

    # error
    $res->{success} = ${$res->{success}} if ref $res->{success};
    unless ($res->{success}) {
        $c->res->code(400);
        return $c->render(json => $res);
    }

    my $id = $res->{items}[0]->{id};

    # redirect
    my $uri = $req->url->clone;
    $uri->path->trailing_slash(1)->merge($id);
    $c->res->code(303); # See Other
    $c->redirect_to($uri->path_query);
}

sub remove {
    my $c = shift;
    my $res = $c->api('User')->delete($c->stash->{id})->result;
    $c->res->code($res->{success} ? 204 : 400);
    $c->render(json => $res);
}

1;
