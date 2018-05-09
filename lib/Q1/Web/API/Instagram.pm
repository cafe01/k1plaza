package Q1::Web::API::Instagram;

use Moo;
use namespace::autoclean;
use JSON qw/ from_json decode_json /;
use Q1::jQuery;
use Data::Printer;
use Carp qw/ croak /;
use Mojo::URL;


has 'tx', is => 'ro', required => 1;

has 'client_id', is => 'ro', lazy => 1,     default => sub{ shift->tx->config->{instagram}{client_id} };
has 'client_secret', is => 'ro', lazy => 1, default => sub{ shift->tx->config->{instagram}{client_secret} };

has 'ua' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        shift->tx->app->ua
    }
);

sub BUILD {
    my ($self) = @_;
    croak __PACKAGE__." requires a 'client_id' and 'client_secret' to work!"
        unless $self->client_id && $self->client_secret;
}


sub get_user_medias {
    my ($self, $user) = @_;
    my $cache = $self->tx->cache;
    my $key = "api-instagram-scrap-user-$user";

    my $data = $cache->get($key);

    unless ($data) {
        $data = $self->_scrap_user_medias($user);
        $cache->set($key, $data, '6h');
    }

    $data;
}

sub _scrap_user_medias {
    my ($self, $user) = @_;
    my $tx = $self->tx;
    my $url = "https://www.instagram.com/$user/";
    my $res = $self->ua->get($url)->result;

    unless ($res->is_success) {
        die "instagram http error ($url): ". $res->message
            if $self->app->mode eq 'development';

        return [];
    }

    my $q = j($res->body);

    # extract javascript data
    my $script;
    $q->find('script')->each(sub{

        if ($_->text =~ /window\._sharedData = /) {
            $script = $_;
        }
    });

    unless ($script) {
        $tx->log->error("[API::Instagram] could not find the <script> tag. Returning empty result.");
        return [];
    }

    # parse data
    warn $script->text;
    my ($javascript_data) = $script->text =~ /.*?(\{.*\})/s;
    my $data = decode_json $javascript_data;

    my $user_data = $data->{entry_data}{ProfilePage}[0]{graphql}{user};
    if ($user_data->{is_private}) {
        $tx->send_system_alert_email("instagram error", "profile '$user' is private");
        $tx->log->error("instagram api: _scrap_user_medias error: profile '$user' is private");
        return [];
    }

    my @medias = map {
        +{
            display_src => $_->{display_url},
            thumbnail_src => $_->{thumbnail_src},
        }
    } map { $_->{node} } @{$user_data->{edge_owner_to_timeline_media}{edges}};

    # return medias
    return \@medias;
}

sub get_medias_by_tag {
    my ($self, $tag) = @_;
    $self->_get('tags/'.$tag.'/media/recent/');
}


sub _get {
    my ($self, $path) = @_;
    my $tx = $self->tx;
    my $cache = $tx->cache;

    $path =~ s!^/!!;
    my $url = Mojo::URL->new('https://api.instagram.com/v1/'.$path);

    # TODO use access_token if available
    $url->query( client_id => $self->client_id );

    # get from cache
    my $cache_key = "api:instagram:$url";
    my $data = $cache->get($cache_key);
    return $data if $data;

    # get from instagram
    $tx->log->debug("[API::Instagram] fetching '$url'");
    my $res = $self->ua->get($url)->result;

    # error
    unless ($res->is_success) {
        $tx->log->error("[API::Instagram] ".$res->message, $res->body);
        return undef;
    }

    # sucess
    $data = $res->json;
    $cache->set($cache_key, $data, '6h');

    return $data;
}






1;

__END__

=pod

=head1 NAME

Q1::Web::API::Instagram

=head1 DESCRIPTION

=cut
