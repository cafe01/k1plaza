package K1Plaza::Snippet::vimeo;

use Mojo::Base -base;
use Data::Printer;


has 'engine' => sub { die 'required' };

has 'tx' => sub {
    shift->engine->context->{tx} or die 'undefined engine->tx';
};

has 'template';


sub get_data {
    my ($self, $params) = @_;
    my $tx = $self->tx;

    my $resource_name;
    foreach (qw/ user channel album /) {
        if ($params->{$_}) {
            $resource_name = $_;
            last;
        }
    }

    # developer error if no stuff
    die "<x-vimeo>: missing one of 'user', 'channel' or 'album' attributes"
        unless $resource_name;

    my $url = sprintf "http://vimeo.com/api/v2/%s/%s/videos.json?page=%d", $resource_name, $params->{$resource_name}, $params->{page} || 1;

    my $data = $tx->cache->get("htto-get-$url");

    unless ($data) {

        my $res = $tx->ua->get($url)->result;

        if ($res->is_success) {
            $data = $res->json;
            $tx->cache->set("htto-get-$url", $data, "1h");
        }
        else {
            # TODO developer warning
            $tx->log->error('<x-vimeo>: http error: '.$res->status_line);
            $data = [];
        }
    }

    $data;
}


sub process {
    my ($self, $element, $plift, $params) = @_;
    my $data = $self->get_data($params);

    # empty element
    $element->html($plift->load_template($self->template))
       if $element->children->size == 0 && $self->template;


    my $tpl = $element->find(".vimeo-item");

    $tpl->render_data({
        id => { '.' => '@data-vimeo-id' },
        tags => '.vimeo-tags',
        title => '.vimeo-title',
        description => { '.vimeo-description' => 'html' },
        url => { '.vimeo-link' => '@href' },
        thumbnail_medium => { selector => '.vimeo-thumbnail, .vimeo-thumbnail-medium', at => '@src' },
        thumbnail_small => { selector => '.vimeo-thumbnail-small', at => '@src' },
        thumbnail_large => { selector => '.vimeo-thumbnail-large', at => '@src' },
        stats_number_of_likes => '.vimeo-likes',
        stats_number_of_plays => '.vimeo-plays',
        stats_number_of_comments => '.vimeo-comments',
        map {(
            "css_thumbnail_$_" => { selector => ".vimeo-thumbnail-${_}-css", data_key => "thumbnail_${_}", callback => sub {
                my ($el, $url) = @_;
                my $style = $el->attr('style') || '';
                $el->attr( style => "$style; background-image: url('$url');"); 
            }}
        )} qw/ small medium large /

        # link => { selector => '.category-link', at => '@href' },
        # posts_count => '.category-item-count',
        # name => {
        #     selector => '.category-name',
        #     callback => sub {
        #         my ($el, $name, $data) = @_;
        #         $el->text($name)
        #            ->attr('data-editable', "category.$data->{id}.name")
        #            ->attr('data-ce-tag', 'p')
        #            ->attr('data-fixture', '');
        #     }
        # },


    }, $data);


}


1;
