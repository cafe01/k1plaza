package K1Plaza::Plugin::Shortcuts;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;
    my $routes = $app->routes;

    $routes->add_shortcut(resource => sub {
        my ($r, $name, %opts) = @_;

        # Prefix for resource
        $opts{prefix} ||= "/.resource/$name";
        $opts{controller} ||= "resource-$name";
        my $resource = $r->any($opts{prefix})->to("$opts{controller}#");

        # List
        $resource->get->to('#list')->name("list_$name");

        # List single
        $resource->get('/:id')->to('#list_single')->name("list_single_$name");

        # Create
        $resource->post->to('#create')->name("create_$name");

        # Update
        $resource->put('/:id')->to('#update')->name("update_$name");

        # Remove
        $resource->delete('/:id')->to('#remove')->name("remove_$name");

        return $resource;
    });
}


1;
