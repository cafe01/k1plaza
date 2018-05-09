package K1Plaza::Resource::Role;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

sub list {
    my $c = shift;

    my $api = $c->api('Role')->join('user_roles');

    $api->push_object_formatter(sub {
        my ($api, $obj, $output) = @_;
        $output->{users} = [$obj->users];
    });

    $c->render(json => $api->list->result);
}

sub list_single {
    my $c = shift;
    my $role = $c->_find_object($c->stash->{id})
        or return $c->reply->not_found;

    $c->render(json => $role->as_hashref);
}

sub _find_object {
    my ($c, $id) = @_;
    my $query = $id =~ /^\d+$/ ? {id => $id} : {rolename => $id};
    $c->api('Role')->find($query)->first;
}


sub list_members  {
    my $c = shift;
    my $role = $c->_find_object($c->stash->{id})
        or return $c->reply->not_found;

    my $res = $c->api('User')->where('user_roles.role_id' => $role->id)
                    ->order_by('first_name')
                    ->list($c->req->query_params->to_hash)
                    ->result;

    $c->render( json => $res );
}


sub add_members  {
    my $c = shift;
    my $role = $c->_find_object($c->stash->{id})
        or return $c->reply->not_found;

    my $data = $c->req->json;
    my @user_ids = map { $_->id } $c->api('User')->where('id' => $data)->list->all_objects;
    $role->update_or_create_related('user_roles', { user_id => $_ })
        for @user_ids;

    $c->rendered(204);
}


sub remove_members {
    my $c = shift;
    my $role = $c->_find_object($c->stash->{id})
        or return $c->reply->not_found;

    # deny remove last admin
    my $success = 1;
    if ($role->rolename eq 'instance_admin' && $role->count_related('user_roles') == 1) {

        $c->app->log->warn('Denying removal of last "instance_admin" member.');
        $success = 0;
    }
    else {

        my @user_ids = map { $_->id } $c->api('User')->where('id' => [split ',', $c->stash->{member_ids}])->list->all_objects;
        $role->delete_related('user_roles', { user_id => \@user_ids });
    }

    $c->render(json => { success => \$success });
}


1;
