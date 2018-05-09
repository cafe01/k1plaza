package Q1::Web::Widget::YoutubeFeed;

use namespace::autoclean;
use Data::Dumper;
use JSON;
use LWP::UserAgent;
use Q1::Moose::Widget;
use Q1::Util qw/pretty_format_duration/;
use Number::Format qw/ format_number /;
use utf8;
use DateTime::Format::ISO8601  qw/strptime/;

extends 'Q1::Web::Widget';

# parent attributes
has '+template', default => 'widget/youtube-feed.html';
has '+is_ephemeral', default => 1;
has '+cache_duration', default => '3h';

# attributes
has 'api_key', is => 'ro', lazy => 1, default => sub { shift->app->config->{google}{api_key} };
has '_ua' => ( is => 'ro', isa => 'LWP::UserAgent', default => sub{ LWP::UserAgent->new( timeout => 5 ) }); # TODO: create app-wide user-agent

# config attributes
has_config 'channel',  isa => 'Str', is_parameter => 1;
has_config 'playlist', isa => 'Str', is_parameter => 1;
has_param 'max_results', isa => 'Int', default  => 50;
has_param 'start', default => 0;
has_param 'limit', default => 0;


sub BUILD {
    my $self = shift;

    die "Invalid config: please supply 'playlist' or 'channel'"
        unless ($self->playlist || $self->channel);
}



sub get_data {
    my ($self) = @_;
    my $cache = $self->app->cache;

    my $max_results = $self->max_results;
    $max_results    = 50 if $max_results > 50;

    my $url = $self->playlist ? sprintf "https://www.googleapis.com/youtube/v3/playlistItems?playlistId=%s&part=snippet&key=%s&maxResults=%d", $self->playlist, $self->api_key, $max_results
                              : sprintf "https://www.googleapis.com/youtube/v3/search?order=date&part=snippet&channelId=%s&key=%s&maxResults=%s", $self->channel, $self->api_key, $max_results;

    $self->_compute_data($url)
}



sub _compute_data {
    my ($self, $url) = @_;

    my $res = $self->_ua->get($url);

    unless ($res->is_success) {
        warn sprintf "Error requesting youtube feed '$url': %d %s", $res->code, $res->status_line;
        return [];
    }

    my $feed = decode_json($res->content);
    my @videos;
    foreach my $entry (@{ $feed->{items} }) {

        my $video = $entry->{snippet};

        # $video->{'publishedAt'} =~ s/\.000Z/+0000/;
        $video->{'publishedAt'} = DateTime::Format::ISO8601->new->parse_datetime($video->{'publishedAt'});
        $video->{id} = $video->{resourceId}{videoId} || $entry->{id}{videoId};
        delete $video->{resourceId};

        push @videos, $video;
    }

    return \@videos;
}



sub render_snippet {
    my ($self, $element, $data) = @_;

    # empty element
    $self->_load_element_template($element)
       if $element->children->size == 0;

    # item template
    my $template = $element->find('.video-item');

    return $element->html('<div class="template-error" style="color:red; border:2px dashed red;">Erro: template não encontrado. (elemento com class "video-item")</div>')
        unless $template->size;

    # feed title
    # $element->find('.video-title')->text($data->{title});

    # start / limit
    my $videos = $data;

    # videos
    my $now = DateTime->now;
    for (my $i = $self->start, my $count = 0; $i <= $#$videos; $i++, $count++ ) {

        # limit
        last if $self->limit && $self->limit == $count;

        my $video = $videos->[$i];
        my $tpl = $template->clone();

        # info
        $tpl->find('.video-'.$_)->text($video->{$_})
            for qw/ title description /;

        # views
        # $tpl->find('.video-views')->text(format_number($video->{views}));

        # rating
        # $tpl->find('.video-likes')->text($video->{rating}{numLikes});
        # $tpl->find('.video-dislikes')->text($video->{rating}{numDislikes});

        # embed url
        my $embed_url = URI->new('//www.youtube.com/embed/'.$video->{id});

        # link
        $tpl->find('a.video-link')->attr( href => 'https://www.youtube.com/watch?v='.$video->{id} );
        $tpl->find('a.video-embed-link')->attr( href => $embed_url->as_string );

        # published
        $tpl->find('.video-published-pretty')->text(pretty_format_duration($now->subtract_datetime($video->{publishedAt})));

        # player
        $tpl->find('iframe.video-player')->each(sub {

            # size
            $_->attr('width', 320) unless $_->attr('width');
            $_->attr('height', int($_->attr('width') / 1.7))
                unless $_->attr('height');

            # src
            $embed_url->query_form(
                rel      => $_->attr('data-rel') || 0,
                autoplay => $_->attr('data-autoplay') || 0
            );

            $_->attr( src => $embed_url->as_string );

            # extra iframe attrs
            $_->attr( frameborder => 0 );
            $_->attr( allowfullscreen => '' );
        });

        # images
        my $thumb = $video->{thumbnails};

        $tpl->find('img.video-thumbnail')->attr( src => $thumb->{'default'}{url} );

        $tpl->find('img.video-thumbnail-'.$_)->attr( src => $thumb->{$_}{url} )
            for qw/ default medium high /;

        $tpl->insert_before($template);
    }

    $template->remove;

}



__PACKAGE__->meta->make_immutable();

__END__

=pod

=head1 NAME

Q1::Web::Widget::YoutubeFeed

=head1 DESCRIPTION

A youtube playlist

=head1 SYNOPSIS

    # in your app_instance.conf

    <widgets>

        <YoutubeFeed videos_foo>

            playlist 97FB7FDC0FAFC2CE
            max_results 15

        </YoutubeFeed>


    </widgets>


=head1 CONFIG

=head2 url

=head2 max_results

=head1 METHODS

=head2 process

=cut
