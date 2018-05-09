package K1Plaza::Snippet::menu;

use Mojo::Base -base;
use Data::Printer;


has 'engine' => sub { die 'required' };

has 'tx' => sub {
    shift->engine->context->{tx} or die 'undefined engine->tx';
};

has 'template' => 'widget/menu';

has 'dropdown_class' => 'dropdown';
has 'dropdown_menu_class' => 'dropdown-menu';
has 'active_class' => 'active';
has 'selector' => '.menu-item';


sub process {
    my ($self, $element, $plift, $params) = @_;
    my $tx = $self->tx;

    if ($element->children->size == 0 && $self->template) {
        $self->_load_template($self->template, $element);
    }

    my $item_tpl = $element->find($self->selector);

    # no template
    return unless $item_tpl->size;

    # static menu
    if ($item_tpl->size > 1) {

        $item_tpl->remove_class($self->active_class)
                 ->find('a')
                 ->remove_class($self->active_class);

        my $current_path = $tx->req->url->path->leading_slash(1)
                                              ->trailing_slash(0)
                                              ->to_string;

        $item_tpl->find(qq/a[href="$current_path"]/)
                 ->parent
                 ->add_class($self->active_class);

        return;
    }

    # render menu
    my $menu_tpl = $item_tpl->parent;
    $item_tpl->detach;

    my $page_tree = $tx->sitemap->page_tree;
    my $rendered_menu = $self->_render_menu($page_tree, $item_tpl, $menu_tpl);
    $menu_tpl->replace_with($rendered_menu);
}

sub _render_menu {
    my ($self, $nodes, $item_tpl, $menu_tpl) = @_;
    my $menu = $menu_tpl->clone;

    my @sorted = sort { ($a->{menu_index}//1) <=> ($b->{menu_index}//1) } @$nodes;
    foreach my $item (@sorted) {
        next if $item->{hidden};
        my $rendered_item = $self->_render_menu_item($item, $item_tpl, $menu_tpl);
        $menu->append($rendered_item);
    }

    $menu;
}

sub _render_menu_item {
    my ($self, $item, $item_tpl, $menu_tpl) = @_;
    my $tx = $self->tx;
    my $rendered_item = $item_tpl->clone;

    # label
    $rendered_item->find('.menu-item-label')->text($item->{menu_label} || $item->{title});

    # path class
    my $path_class = $item->{fullpath};
    $path_class =~ tr/\//-/;
    $rendered_item->add_class("menu-item-$path_class");

    # link
    $rendered_item->find('a')->each(sub{

        $_->add_class("link-to-$path_class");

        if ($item->{path_only}) {
            $_->remove_attr('href');
        } else {
            $_->attr('href', $tx->uri_for_page($item));
        }
    });

    # active item

    if (exists $tx->stash->{fullpath} && $tx->stash->{fullpath} eq $item->{fullpath}) {
        $rendered_item->add_class($self->active_class)->find('a')->add_class($self->active_class);
    }

    if ($item->{children}) {
        #warn "Rendering submenu $item->{title}\n";
        my $submenu = $self->_render_menu($item->{children}, $item_tpl, $menu_tpl);
        unless ($submenu->children->size == 0) {
            $submenu->add_class($self->dropdown_menu_class);
            $rendered_item->add_class($self->dropdown_class);
            $rendered_item->append($submenu);
        }
    }

    $rendered_item;
}





sub _load_template {
    my ($self, $tpl_name, $element) = @_;

    # strip deprecated .html suffix
    $tpl_name =~ s/\.html$//;

    my $dom = $self->engine->load_template($tpl_name);
    $element->html($dom);
}

1;
