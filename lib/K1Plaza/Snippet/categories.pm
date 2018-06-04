package K1Plaza::Snippet::categories;

use Mojo::Base -base;
use Data::Printer;


has 'engine' => sub { die 'required' };

has 'tx' => sub {
    shift->engine->context->{tx} or die 'undefined engine->tx';
};

has 'template' => 'widget/categories';
has 'include_empty';
has 'source_widget' => sub { die '<x-category>: missing "source_widget" attribute' };
has 'widget' => sub { shift->source_widget || die '<x-category>: missing "widget" attribute' };


sub get_data {
    my ($self) = @_;
    my $tx = $self->tx;

    # TODO cache result based on blog version

    my $widget = $tx->widget($self->widget);
    my $api = $tx->api('Category', { widget => $widget })
                  ->join('blogpost_categories')
                  ->group_by('me.id')
                  ->set_search_attribute('+columns' => { posts_count => {
                      count => 'blogpost_categories.blogpost_id',
                      -as => 'posts_count'
                  }});

    $api->having( posts_count => { '>' => 0 })
        unless $self->include_empty;

    # create link
    my $route_name = "widget-${\ $widget->name }-category-category";
    my $sitemap = $tx->sitemap;
    $api->add_object_formatter(sub {
        my $item = $_[2];
        $item->{link} = $tx->site_url_for("widget-${\ $widget->name }-category-category", { category => $item->{slug} })
            and $item->{link} = $item->{link}->to_abs->to_string;
                           
    });

    $api->list->result;
}


sub process {
    my ($self, $element, $plift, $params) = @_;
    my $data = $self->get_data;

    # empty element
    $element->html($plift->load_template($self->template))
       if $element->children->size == 0 && $self->template;

    # item template
    my $template = $element->find('.category-item');

    return $element->html('<div class="template-error" style="color:red; border:2px dashed red;">Erro: template não encontrado. (elemento com class "category-item")</div>')
        unless $template->size;

    # render
    $template->render_data({
        link => { selector => '.category-link', at => '@href' },
        posts_count => '.category-item-count',
        name => {
            selector => '.category-name',
            callback => sub {
                my ($el, $name, $data) = @_;
                $el->text($name)
                   ->attr('data-editable', "category.$data->{id}.name")
                   ->attr('data-ce-tag', 'p')
                   ->attr('data-fixture', '');
            }
        },


    }, $data->{items});

}


1;
