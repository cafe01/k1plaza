package K1Plaza::Snippet::gallery;

use Mojo::Base -base;
use Data::Printer;


has 'name' => '';
has 'template' => 'widget/gallery';
has 'start' => 0;
has 'limit';
has 'fixtures';

has 'engine' => sub { die 'required' };

has 'tx' => sub {
    shift->engine->context->{tx} or die 'undefined engine->tx';
};

has 'widget' => sub {
    my $self = shift;
    $self->tx->widget($self->name, {
        $self->fixtures ? (fixtures => $self->fixtures) : ()
    });
};

sub process {
    my ($self, $element, $plift) = @_;

    # load template file
    if ($element->children->size == 0 && $self->template) {
        $self->_load_template($self->template, $element);
    }

    my $template = $element->find('.media-item')->first;
    unless ($template->size) {
        $self->tx->log->warn("[gallery=${\ $self->name }] missing media template element '.media-item'");
        return;
    }

    my $medias = $self->widget->data->{medias};

    $medias = [splice(@$medias, $self->start, $self->limit || scalar(@$medias))]
        if $self->start || $self->limit;

    my $media_metadata = $self->widget->media_metadata;
    my $schema = {
        url => { selector => 'a.media-link', at => '@href' },
        image => {
            selector => '.media-image',
            data_key => 'uuid',
            callback => sub {
                my ($img, $uuid, $media) = @_;

                $img->attr('alt', $media->{description} || $media->{title} || '')
                    unless defined $img->attr('alt');

                $img->attr('src', $self->tx->uri_for_media($media, {
                    crop    => 1,
                    width   => $img->attr('data-width') || $img->attr('width'),
                    height  => $img->attr('data-height') || $img->attr('height'),
                    zoom    => $img->attr('data-zoom')
                }));
            }
        },

        file_name => '.media-file-name',

        image_css => {
            selector => '.media-image-css',
            data_key => 'uuid',
            callback => sub {
                my ($img, $uuid, $media) = @_;

                my $url = $self->tx->uri_for_media($media, {
                    crop    => 1,
                    width   => $img->attr('data-width') || $img->attr('width'),
                    height  => $img->attr('data-height') || $img->attr('height'),
                    zoom    => $img->attr('data-zoom')
                });

                $img->attr('style', sprintf "%s; background-image:url(%s);", $img->attr('style') || '', $url);
            }
        },

        # (map { "_meta_".$_ => { selector => '.media-meta-'.$_, data_key => $_ } } keys %{$self->media_metadata}),

        (map { my $meta = $_; "_meta_".$_ => { selector => '.media-meta-'.$_, data_key => 'id', callback => sub {
            my ($el, $id, $media) = @_;
            my $meta_spec = $media_metadata->{$meta};
            # save attr value before its removed by render_data()
            my $default_render_at = $meta_spec->{data_type} eq 'html' ? 'html' : 'text';
            my $render_at = $el->attr('data-plift-render-at') || $default_render_at;
            $el->render_data({ value => { '.' => $render_at } }, { value => $media->{$meta} });

            # my $ce_tag = $render_at =~ /href/i ? 'a' : 'p';
            return if $render_at =~ /\@href/i;
            $el->attr('data-editable', "gallery.".$self->name.".$id.$meta")
               ->attr('data-ce-tag', 'p');

            $el->attr('data-fixture', '') unless $meta_spec->{data_type} eq 'html';

        }}} keys %$media_metadata),
    };

    $template->render_data($schema, $medias);

}

sub _load_template {
    my ($self, $tpl_name, $element) = @_;

    # strip deprecated .html suffix
    $tpl_name =~ s/\.html$//;

    my $dom = $self->engine->load_template($tpl_name);
    $element->html($dom);
}

1;
