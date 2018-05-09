package K1Plaza::Snippet::instagram;

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
	my $api = $tx->api('Instagram');

	if ($params->{user}) {
	    return $api->get_user_medias($params->{user});
	}
	elsif ($params->{tag}) {
	    return $api->get_medias_by_tag($params->{tag});
	}
    else {
        $tx->log->warn("[Instagram] missing 'user' or 'tag' widget param.");
        return;
    }
}


sub process {
    my ($self, $element, $plift, $params) = @_;
    delete @$params{qw/ engine /};

    # widget
    my $tx = $self->tx;

    # template file
    $element->html($plift->load_template($self->template))
        if $element->children->size == 0 && $params->template;

    # data
    my $data = $self->get_data($params);
    $element->remove and return unless $data;


    # item template
    my $template = $element->find('.media-item');

    return $element->html('<div class="template-error" style="color:red; border:2px dashed red;">Erro: template não encontrado. (elemento com class ".media-item")</div>')
            unless $template->size;

    my $medias = $params->{user} ? $data : $data->{data};

    for (my $i = 0; $i < @$medias; $i++) {

        my $tpl = $template->clone();
        my $media = $medias->[$i];

        $tpl->find('.media-thumbnail')->attr( src => $media->{thumbnail_src} );
        $tpl->find('.media-thumbnail-link')->attr( href => $media->{thumbnail_src} );

        $tpl->find('.media-image')->attr( src => $media->{display_src} );
        $tpl->find('.media-link')->attr( href => $media->{display_src} );

        $tpl->insert_before($template);

        last if $params->{limit} && ($i+1) == $params->{limit};
    }

    $template->remove;

}

1;
