package Q1::Web::Widget::Agenda;

use utf8;
use namespace::autoclean;
use Q1::Moose::Widget;
use Data::Dumper;
use Q1::Utils::ConfigLoader;
use HTML::Strip;

extends 'Q1::Web::Widget';
with 'Q1::Role::Widget::DBICResource';

has '+template', default => 'widget/agenda.html';
has '+backend_view' => ( default => 'agenda' );

has_config 'page_path', isa => 'Str', default => ''; # TODO: introspect this value from the SiteMap or transform into a param

has_argument 'year';
has_argument 'month';
has_argument 'permalink';

has_param 'page', isa => 'Int', default => 1;
has_param 'start', isa => 'Int', default => 0;
has_param 'limit', isa => 'Int', default => 250;

has_param 'columns', isa => 'Int', default => 0;
has_param 'include_unpublished', default => 0;
has_param 'period', default => 'future';



sub _api_class { 'Agenda' }

sub routes {

    my $year        = qr/\d{4}/;
    my $month       = qr/\d\d?/;
    my $permalink   = qr/[a-z0-9_-]+/;

    [
        [':year', [year => $year]],
        [':year/:month', [year => $year, month => $month]],
        [':year/:month/:permalink', [year => $year, month => $month, permalink => $permalink]],
    ]
}


sub load_fixtures {
    my ($self) = @_;
    my $api = $self->_api;

    $api->create({
        title => 'Lorem Ipsum Dólor Sit Amet Consectetur!',
        content => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        date => DateTime->now->add( days => int(rand 420)),
        ticket_url => 'http://event.com/buy-the-ticket',
        price => int(rand 500),
        is_soldout => int(rand(2)),
        is_canceled => int(rand(2)),
        venue => 'The Best Place',
        location => 'Vitoria, ES',
        lat => -34.397,
        lng => 150.644
    }) for (1..14);
}


sub before_render_page {
    my ($self, $tx) = @_;
    my $data = $self->data;

    # not found
    if ($data->{is_permalink_result} && $data->{total} == 0) {
        $tx->render( html => '404', { no_finalize => 1 });
        return;
    }

    if ($data->{is_permalink_result}) {

        my $item = $data->{items}[0];
        $tx->stash->{title} = $item->{title};

        # stash post
        $tx->stash->{current_agenda_item} = $item;

        # single post template
        $tx->stash->{template} .= '.single'
            if $tx->renderer->get_renderer_by_format('html')->find_template_file($tx, $tx->stash->{template}.'.single');

        # opengraph
        my $og = ($tx->stash->{opengraph} //= {});

        $og->{url}   = $self->uri_for_item($item);
        $og->{title} = $item->{title};
        $og->{image} = $tx->uri_for_media($item->{thumbnail_url}, { scale => '250x250', crop => 1 })
            if $item->{thumbnail_url};

        # description
        my $excerpt = $item->{excerpt};
        my $hs = HTML::Strip->new( decode_entities => 1 );
        $og->{description} = $hs->parse( $excerpt );
        $hs->eof;
    }
}


sub render_snippet {
    my ($self, $element, $data) = @_;
    my $is_permalink_result = $data->{is_permalink_result};
    my $tx = $self->tx;

    # empty element
    $self->_load_element_template($element)
       if $element->children->size == 0;

    # hide-for-single / show-for-single
    $element->find($is_permalink_result ? '.hide-for-single' : '.show-for-single')->remove();

    # find/choose post template
    my $template;

    if ($is_permalink_result) {
        $template = $element->find('.agenda-item')->first;
        $element->find('.agenda-list-item')->remove;
    }
    else {
        $template = $element->find('.agenda-list-item')->first;
        if ($template->size) {
           $element->find('.agenda-item')->remove;
        } else {
           $template = $element->find('.agenda-item')->first;
        }
    }

    # warn "Agenda template:\n".$template->as_html;

    return $element->html('<div class="template-error" style="color:red; border:2px dashed red;">Erro: template não encontrado.</div>')
            unless $template->size;


    for (my $i = 0; $i < scalar @{$data->{items}}; $i++ ) {

        # limit
        last if $self->limit && $self->limit == $i;


        my $item = $data->{items}[$i];
        my $tpl = $template->clone;

        # title
        $tpl->find('.agenda-item-title')->each(sub{
            $_->text($item->{title});
            $_->attr( title => $item->{title} ) unless $_->attr('title');
        });

        # venue
        $tpl->find('.agenda-item-venue')->text($item->{venue});

        # location
        $tpl->find('.agenda-item-location')->text($item->{location});

        # link
        $tpl->find('.agenda-item-link')->attr(href => $self->uri_for_item($item));

        # ticket-link
        $tpl->find('.agenda-item-ticket-link')->attr(href => $item->{ticket_url})->text($item->{ticket_url});

        # ticket price
        $tpl->find('.agenda-item-ticket-price')->text($item->{price}); # TODO format number

        # date
        $tpl->find('.agenda-item-date')->datetime($item->{date});

        # thumbnail
        $tpl->find('.agenda-item-thumb')->each(sub{
            $_->attr( src => $self->tx->uri_for_media($item->{thumbnail_url}, { crop => 1, width => $_->attr('width'), height => $_->attr('height'), zoom => $_->attr('data-zoom') }) );
        }) if $item->{thumbnail_url};

        # excerpt
        $tpl->find('.agenda-item-excerpt')->html($item->{excerpt});

        # content
        $tpl->find('.agenda-item-content')->html($item->{content});

        # map
        if ($item->{lat} && $item->{lng}) {

            $tpl->find('.agenda-item-map')->each(sub{

                my $map_widget = $tx->widget('GoogleMap', undef, undef, {
                    lat => $item->{lat},
                    lng => $item->{lng},
                    zoom => $_->attr('data-map-zoom') || 14,
                    maptype => $_->attr('data-map-type') || 'ROADMAP'
                });

                $map_widget->render_snippet($_);
            });
        }
        else {
            $tpl->find('.agenda-item-map')->remove;
        }


        # append
        $tpl->insert_before($template);

    }

    $template->remove;
}



sub uri_for_item {
    my ($self, $item) = @_;
    my $date = $item->{date};

    unless (blessed $date) {
        my $formatter = DateTime::Format::Strptime->new(
            locale    => 'pt_BR',
            pattern   => '%F %T', # 2012-07-24 14:40:09
            time_zone => 'UTC',
        );

        $date = $formatter->parse_datetime($date);
    }

    return $self->tx->uri_for($self->page_path, [$date->year, sprintf('%02d', $date->month), $item->{permalink}])
}

__PACKAGE__->meta->make_immutable();

1;


__END__

=pod

=head1 NAME

Q1::Web::Widget::Agenda

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
