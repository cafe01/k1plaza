package K1Plaza::API::Unsplash;

use Mojo::Base -base;
use Data::Printer;


has 'tx' => sub { die 'required' };
has 'access_key' => sub { shift->tx->config->{unsplash}{access_key} || die 'Missing "unsplash.access_key" app config.' };


sub get {
    my ($self, $endpoint, $query) = @_;

    my $log = $self->tx->log;
    my $ua = $self->tx->app->ua;

    my $url = Mojo::URL->new('https://api.unsplash.com/');
    $url->path($endpoint);
    $url->query($query);

    my $result = $self->tx->app->ua->get($url, { Authorization => "Client-ID ".$self->access_key })->result;

    unless ($result->is_success) {
        $log->error("Unsplash API request failed with code: ", $result->code, $result->json || $result->body);
        return [];
    }

    my $data = $result->json;
    $data;
}


1;
