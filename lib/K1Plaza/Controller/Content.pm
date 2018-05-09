package K1Plaza::Controller::Content;
use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;


sub save {
    my ($c) = @_;

    # get data
    my $params = $c->req->body_params->to_hash;

    # demux
    my %data;
    foreach my $key (keys %$params) {

        my @subkeys = split /\./, $key;
        my $ref = \%data;
        for (my $i = 0; $i < @subkeys; $i++) {

            my $subkey = $subkeys[$i];
            if ($i == $#subkeys) {
                $ref->{$subkey} = $params->{$key};
            }
            else {
                $ref->{$subkey} //= {};
                $ref = $ref->{$subkey};
            }
        }
    }

    # db tx
    my $db_tx = sub {

        # dispatch
        foreach my $ns (keys %data) {

            my $method = $c->can('_save_'.$ns);
            die "No save handler for content namespace '$ns'" unless $method;
            $c->$method($data{$ns});
        }

        1;
    };

    my $success; $success = try {
        $c->app->schema->txn_do($db_tx);
    }
    catch {
        my $error = $_;
        if ($error =~ /at .* line \d+\./) {
            die $error;
        }
        else {
            $c->app->log->error("[ContentEditor] save error: $error");
            $c->res->code(400);
            $success = 0;
        }
    };

    $c->render(json => { success => $success });
}


sub _save_data {
    my ($c, $data) = @_;

    my $api = $c->api('Data');
    foreach my $key (keys %$data) {
        $api->set($key, $data->{$key});
    }
}


sub _save_blog {
    my ($c, $data) = @_;


    foreach my $widget_name (keys %$data) {

        my $widget_data = $data->{$widget_name};

        foreach my $item_id (keys %$widget_data) {

            my $item_data = $widget_data->{$item_id};
            $item_data->{id} = $item_id;
            $c->api('Blog', { widget => $c->widget($widget_name) })
                  ->update($item_data);
        }
    }
}


sub _save_category {
    my ($c, $data) = @_;

    foreach my $id (keys %$data) {

        my $name = $data->{$id}{name};
        next unless $name;
        $c->api('Category')->update({
            id => $id,
            name => $name
        });
    }
}

sub _save_tag {
    my ($c, $data) = @_;
    my $app_instance_id = $c->app_instance->id;
    foreach my $id (keys %$data) {

        my $name = $data->{$id}{name};
        next unless $name;
        $c->app->schema->resultset('Tag')->search({
            app_instance_id => $app_instance_id,
            id => $id,
        })->update({ name => $name });
    }
}


sub _save_gallery {
    my ($c, $data) = @_;

    foreach my $widget_name (keys %$data) {

        my $widget_data = $data->{$widget_name};

        my $widget = $c->widget($widget_name);
        foreach my $item_id (keys %$widget_data) {

            my $item_data = $widget_data->{$item_id};
            $item_data->{id} = $item_id;
            $c->api('Media', { widget => $c->widget($widget_name) })
              ->update($item_data);
        }
    }
}

sub _save_expo {
    my ($c, $data) = @_;

    foreach my $widget_name (keys %$data) {

        my $widget_data = $data->{$widget_name};

        # my $widget = $c->widget($widget_name);
        my $api = $c->api('Expo', { widget => $c->widget($widget_name) });
        foreach my $item_id (keys %$widget_data) {

            my $item_data = $widget_data->{$item_id};
            $item_data->{id} = $item_id;
            $api->update($item_data);
        }
    }
}


1;
