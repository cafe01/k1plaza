package K1Plaza::Developer::Resource::Settings;

use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

sub data {
    shift->api('Data', { app_instance_id => -1 });
}

sub update_settings {
    my ($c, $data) = @_;
    my $settings = $c->developer_settings;
    @$settings{keys %$data} = values %$data;
    $c->developer_settings($settings);
}

sub list {
    my ($c) = @_;
    $c->render(json => $c->developer_settings);
}

sub create {
    my ($c) = @_;
    my $data = $c->req->json || {};
    $c->developer_settings($data);
    $c->rendered(204);
}


sub update_token {
    my ($c) = @_;
    my $data = $c->req->json || {};
    return $c->rendered(400) unless $data->{token};

    # validate token
    $c->render_later;
    $c->app->ua->get_p('https://api.github.com/user' => {"Authorization" => "token $data->{token}"})->then(sub {
        my $tx = shift;
        my $res = $tx->result;

        # fail
        unless ($res->is_success && $res->json->{id}) {
            $c->log->error("Github token validation failed:", $res->body);
            return $c->rendered(400);
        }

        # all good
        $c->update_settings({
            github_access_token => $data->{token},
            github_account => $res->json,
        });

        $c->rendered(201);

    }, sub { $c->rendered(400) });
}



1;
