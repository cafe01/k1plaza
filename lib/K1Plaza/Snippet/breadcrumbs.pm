package K1Plaza::Snippet::breadcrumbs;

use Mojo::Base -base;
use Data::Printer;


has 'engine' => sub { die 'required' };

has 'tx' => sub {
    shift->engine->context->{tx} or die 'undefined engine->tx';
};


sub get_data {
    my ($self) = @_;
    my $tx = $self->tx;
    return [] unless defined $tx->sitemap;

    my @trail;
    my $sitemap = $tx->app->routes->find('website');
    my $root = $sitemap->find("website-root")->pattern->defaults;
    my $current_page = $tx->stash;

    # root
    push @trail, { title => $root->{title}, url => $tx->url_for('/')->to_abs->to_string };

    # stashed trails
    push @trail, @{$tx->stash->{breadcrumbs}}
        if ref $tx->stash->{breadcrumbs} eq 'ARRAY';

    # current
    push @trail, { title => $current_page->{title}, url => $tx->url_for->to_abs->to_string }
        if $current_page->{fullpath} ne $root->{fullpath};

    delete $trail[-1]->{url};

    my $i = 1;
    $_->{position} = $i++ for @trail;

    \@trail;
}


sub process {
    my ($self, $element, $plift, $params) = @_;

    my $template = $element->find('.breadcrumb-item')->first;
    return unless $template->size; # TODO emit error

    # microdata
    $element->attr({ itemscope => '',  itemtype => "http://schema.org/BreadcrumbList" });
    $template->attr({ itemscope => '', itemtype => "http://schema.org/ListItem", itemprop => "itemListElement" });
    $template->find('.breadcrumb-title')->attr( itemprop => 'name' );
    $template->append('<meta itemprop="url" /><meta itemprop="position" />');

    # render
    $template->render_data({
        title => '.breadcrumb-title',
        url   => { '.breadcrumb-link' => '@href' },
        meta_url => { selector => 'meta[itemprop=url]', at => '@content', data_key => 'url' },
        position => { 'meta[itemprop=position]' => '@content' }
    }, $self->get_data);

    # separator
    my $separator = $element->find('.breadcrumb-item-separator')->detach;
    if ($separator->size) {
        my $items = $element->find('.breadcrumb-item');
        my $size = $items->size;
        $items->each(sub {
            my ($i, $el) = @_;
            return if $i + 1 == $size;
            $separator->clone->insert_after($el);
        });
    }
}


1;
