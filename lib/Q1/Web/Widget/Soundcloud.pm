package Q1::Web::Widget::Soundcloud;

use utf8;
use namespace::autoclean;
use JSON;
use Q1::Moose::Widget;
use Encode qw/ encode /;
use Q1::jQuery;
use URI;
use Data::Printer;
use DateTime;

extends 'Q1::Web::Widget';

has '+is_ephemeral', default => 1;
has '+cache_duration', default => '12h';

has 'client_id'     => ( is => 'ro', isa => 'Str', default => '2941bc55aa9da0d2a37ac28f0a50f49b' ); # TODO: do not hardcode this
has 'client_secret' => ( is => 'ro', isa => 'Str', default => 'cd746830fe6c3cdd6da48b4a14731efb' );

has_config 'page_path', isa => 'Str', default => '';

has_param 'user',     isa => 'Str', required => 1, is_config => 1;
has_param 'playlist', isa => 'Str', is_config => 1;
has_param 'limit',    isa => 'Int', default => 10;

has_argument 'track';

sub routes {
    [
        ["/track/:track", [track => qr/\d+/]]
    ]
};

sub get_data {
    my ($self, $tx, $args, $params) = @_;

    return $self->_get_track($self->track)
        if $self->track;

    return $self->_get_playlist
        if $params->{playlist};

    return $self->_get_playlists;
}

sub _get_track {
    my ($self, $track_id) = @_;
    my $res = $self->_request(sprintf 'http://api.soundcloud.com/tracks/%s.json?client_id=%s', $track_id, $self->client_id);

    return $res if $res->{error};

    return { success => 0, error => 'Requested track of another user: ' }
        unless $res->{user}{permalink} eq $self->user;

    $res;
}


sub _get_playlist {
    my ($self) = @_;

    # build api url
    my $url = sprintf 'http://api.soundcloud.com/resolve.json?client_id=%s&url=http://soundcloud.com/%s/sets/%s/',
        $self->client_id,
        $self->user,
        $self->playlist;

    # API request
    $self->_request($url);
}



sub _get_playlists {
    my ($self) = @_;

    my $url = sprintf 'http://api.soundcloud.com/resolve.json?client_id=%s&url=http://soundcloud.com/%s/sets',
        $self->client_id,
        $self->user;

    $self->_request($url);
}



sub _request {
    my ($self, $url) = @_;

    my $res = $self->app->ua->get($url)->result;
    return { success => 0, error => "Erro ao acessar API do soundcloud." }
        unless $res->is_success;

    $res->json;
}



sub render_snippet {
    my ($self, $element, $data) = @_;

    # error
    if (ref $data eq 'HASH' && $data->{error}) {
        return $element->html('<!-- soundcloud error -->');
    }

    # render single track
    if ($self->track) {

        my $template = $element->find('.soundcloud-item');
        return $element->html('<div style="color:red; border: 2px dashed red;">ERRO: soundcloud template não encontrado (class="soundcloud-item")</div>')
            unless $template->size;

        # show/hide
        my $parent = $element->parent;
        $parent->find('.show-for-single-track')->remove_class('.show-for-single-track');
        $parent->find('.hide-for-single-track')->remove;

        # back link
        $element->find('.soundcloud-back-link')->attr( href => $self->tx->uri_for($self->page_path) );

        return $self->_render_track($template, $data);
    }

    # single playlist
    if ($self->playlist) {
        return $self->_render_playlist($element, $data);
    }

    # multiple playlists
    my $template = $element->find('.soundcloud-playlist-item');
    return $element->html('<div style="color:red; border: 2px dashed red;">ERRO: soundcloud template não encontrado (class="soundcloud-playlist-item")</div>')
        unless $template->size;

    foreach my $item (@$data) {
        my $tpl = $template->clone;
        $self->_render_playlist($tpl, $item);
        $tpl->insert_before($template);
    }
    $template->remove;
}

sub _render_track {
    my ($self, $tpl, $track) = @_;

    # player options
    my %default_player_options = (
        color => 'ff6600',
        show_artwork => 'true',
        auto_play => 'false',
        show_comments => 'true',
        show_playcount => 'true'
    );

    # title
    $tpl->find('.soundcloud-item-title')->text($track->{title});

    # link
    $tpl->find('a.soundcloud-item-link')->attr( href => $self->uri_for_track($track).'' );

    # artwork
    $tpl->find('.soundcloud-item-artwork')->each(sub{

        my $url = $track->{artwork_url};

        if (my $size = $_->attr('data-artwork-size')) {
            $_->remove_attr('data-artwork-size');
            $url =~ s/large/$size/;
        }

        $_->attr( src => $url );

    }) if $track->{artwork_url};

    # waveform url
    $tpl->find('.soundcloud-item-waveform')->attr( src => $track->{waveform_url} );

    # playcount, favcount, commentcount, downloadcount
    $tpl->find('.soundcloud-item-playcount')->text($track->{playback_count});
    $tpl->find('.soundcloud-item-favcount')->text($track->{favoritings_count});
    $tpl->find('.soundcloud-item-commentcount')->text($track->{comment_count});
    $tpl->find('.soundcloud-item-downloadcount')->text($track->{download_count});

    # description
    $tpl->find('.soundcloud-item-description')->text($track->{description} || '');

    # label
    $tpl->find('.soundcloud-item-label')->text($track->{label_name} || '');

    # genre
    $tpl->find('.soundcloud-item-genre')->text($track->{genre} || '');

    # duration
    $tpl->find('.soundcloud-item-duration')->each(sub{
        $_->text(_format_duration($track->{duration}, $_->{'data-time-format'}))
    });

    # permalink
    $tpl->find('.soundcloud-item-external-link')->attr( href => $track->{permalink_url});

    # html5 player
    # <iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=http%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F87125460&amp;color=ff6600&amp;auto_play=false&amp;show_artwork=true"></iframe>
    $tpl->find('.soundcloud-item-player')->each(sub{

        my $player = $_;
        my %options;
        if (defined $player->attr('data-soundcloud-player-options')) {
            my $uri = URI->new('?'.$player->attr('data-soundcloud-player-options'));
            %options = $uri->query_form if $uri->query =~ /=/;
            %options = (%default_player_options, %options);
            $player->remove_attr('data-soundcloud-player-options');
        }

        my $player_url = URI->new('https://w.soundcloud.com/player/');
        $player_url->query_form(%options, url => $track->{uri});

        my $iframe = j('<iframe scrolling="no" frameborder="no"></iframe>');
        $iframe->attr( src    => "$player_url");
        $iframe->attr( width  => $player->attr('width') || '100%');
        $iframe->attr( height => $player->attr('height') || '100%');

        $player->html($iframe->as_html);

    });

    $tpl->find('.soundcloud-item-player-link')->each(sub{

        my %options;
        if (defined $_->attr('data-soundcloud-player-options')) {
            my $uri = URI->new('?'.$_->attr('data-soundcloud-player-options'));
            %options = $uri->query_form if $uri->query =~ /=/;
            %options = (%default_player_options, %options);
            $_->remove_attr('data-soundcloud-player-options');
        }

        my $url = URI->new('https://w.soundcloud.com/player/');
        $url->query_form(%options, url => $track->{uri});
        $_->attr( href => "$url");
    });

    # flash player
    # <object height="81" width="100%"><param name="movie" value="https://player.soundcloud.com/player.swf?  url=http%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F87125460&amp;color=ff6600&amp;auto_play=false&amp;show_artwork=true&amp;show_playcount=true&amp;show_comments=true"></param><param name="allowscriptaccess" value="always"></param><embed allowscriptaccess="always" src="https://player.soundcloud.com/player.swf?url=http%3A%2F%2Fapi.soundcloud.com%2Ftracks%2F87125460&amp;color=ff6600&amp;auto_play=false&amp;show_artwork=true&amp;show_playcount=true&amp;show_comments=true" type="application/x-shockwave-flash" width="100%" height="81"></embed></object>
    $tpl->find('.soundcloud-item-flashplayer')->each(sub{

        my $player = $_;
        my %options;

        if (defined $player->attr('data-soundcloud-player-options')) {
            my $uri = URI->new('?'.$player->attr('data-soundcloud-player-options'));
            %options = $uri->query_form if $uri->query =~ /=/;
            %options = (%default_player_options, %options);
            $player->remove_attr('data-soundcloud-player-options');
        }

        my $player_url = URI->new('https://player.soundcloud.com/player.swf');
        $player_url->query_form(%options, url => $track->{uri});

        my $object = j('<object><param name="movie"></param><param name="allowscriptaccess" value="always"></param><embed allowscriptaccess="always" type="application/x-shockwave-flash"></embed></object>');
        $object->find('param[name=movie]')->attr(value => "$player_url");
        my $embed = $object->find('embed');
        $embed->attr( src => "$player_url" );
        $object->attr( width  => $player->attr('width') || '100%');
        $object->attr( height => $player->attr('height') || '100%');
        $embed->attr( width  => $player->attr('width') || '100%');
        $embed->attr( height => $player->attr('height') || '100%');

        $player->html($object->as_html);
    });
}


sub _render_playlist {
    my ($self, $element, $data) = @_;

    my $template = $element->find('.soundcloud-item');
    return $element->html('<div style="color:red; border: 2px dashed red;">ERRO: soundcloud template não encontrado (class="soundcloud-item")</div>')
        unless $template->size;

    # title
    $element->find('.soundcloud-title')->text($data->{title});

    # duration
    $element->find('.soundcloud-duration')->each(sub{
        $_->text(_format_duration($data->{duration}, $_->{'data-time-format'}))
    });

    for (my $i = 0; $i < scalar @{$data->{tracks}}; $i++) {

        last if $self->limit && $i == $self->limit;

        my $track = $data->{tracks}->[$i];

        # clone
        my $tpl = $template->clone;

        # render
        $self->_render_track($tpl, $track);

        # add item
        $tpl->insert_before($template);
    }

    $template->remove;

}

sub _format_duration {
    my ($duration, $format) = @_;
    $format ||= '%H:%M:%S';
    my $text = DateTime->from_epoch( epoch => ($duration / 1000) || 0 )->strftime($format);
    $text =~ s/^00://;
    $text;
}

sub uri_for_track {
    my ($self, $track) = @_;
    $self->tx->uri_for($self->page_path, ['track', $track->{id}]);
}

__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=head1 NAME

Q1::Web::Widget::Soundcloud

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head2 process

Arguments: $action, \%params

=head2 call

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
