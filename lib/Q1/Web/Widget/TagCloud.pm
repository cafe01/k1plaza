package Q1::Web::Widget::TagCloud;

use utf8;
use namespace::autoclean;
use List::Util qw();
use Q1::Moose::Widget;

extends 'Q1::Web::Widget';


has '+is_ephemeral', default => 1;

has 'widget' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->tx->widget($self->source_widget);
    }
);

has_param 'source_widget' => ( is => 'rw', isa => 'Str', required => 1);
has_param 'uri_prefix'    => ( is => 'rw', isa => 'Str', default  => '/tag/');
has_param 'css_prefix'    => ( is => 'rw', isa => 'Str', default  => 'tag-cloud');
has_param 'unit'          => ( is => 'rw', isa => 'Str', default  => 'px');
has_param 'max_font_size' => ( is => 'rw', isa => 'Int', lazy => 1, default => 20 );
has_param 'min_font_size' => ( is => 'rw', isa => 'Int', lazy => 1, default => 5 );

has_param  'shuffle'       => ( is => 'rw', isa => 'Bool', default => 0 );
has_param  'skip_font_style' => ( is => 'rw', isa => 'Bool', default => 0 );


sub _mangle_cache_key {
	my ($self, $key) = @_;
    $key.':'.$self->widget->_cache_key;
}

sub get_data {
	my ($self, $tx) = @_;

	# get widget
	my $widget = $self->widget;

	# get tag cloud
	my $tag_api = $self->tx->api('Tag', { widget => $widget });
    my $params = {
	    max_font_size  => $self->max_font_size,
	    min_font_size  => $self->min_font_size
	};

    if ($widget->isa('Q1::Web::Widget::Blog')) {
        $params->{relationship} = { 'blogpost_tags' => 'blogpost' };
    }
    elsif ($widget->isa('Q1::Web::Widget::Expo')) {
        $params->{relationship} = { 'expo_tags' => 'expo' };
    }
    else {
        die "[TagCloud] can't handle this type of widget: ".ref($widget);
    }

    $tag_api->generate_tag_cloud($params);
}





sub render_snippet {
    my ($self, $element, $data) = @_;
    my $app  = $self->app;
    my $css_prefix = $self->css_prefix;

    # empty element
    if ($element->children->size == 0) {
        $element->append("<ul class='$css_prefix'><li class='$css_prefix-item'><a class='$css_prefix-item-name'></a></li></ul>")
    }

    # tpl
    my $tpl = $element->find(".$css_prefix-item")->first;
    return unless $tpl->size;
    my $container = $tpl->parent;
    $tpl = $tpl->detach;

    my $orig_style = $tpl->attr('style') || '';

    my @items = $self->shuffle ? List::Util::shuffle @{$data->{items}} : @{$data->{items}};

    foreach my $item (@items) {

        # local clone
        my $tpl = $tpl->clone;

        # name
        $tpl->find(".$css_prefix-item-name")
            ->text($item->{name})
            ->attr('data-editable', "tag.$item->{id}.name")
            ->attr('data-ce-tag', 'p')
            ->attr('data-fixture', '');

        # link
        my $uri = join $self->uri_prefix =~ /\/$/ ? '' : '/', $self->uri_prefix, $item->{slug};
        $tpl->find('a')->attr('href', $self->tx->uri_for($uri));

        # font-size
        my $size = sprintf '%.2f%s', $item->{font_size}, $self->unit;
        $tpl->attr('style', "font-size:$size; $orig_style")
            unless $self->skip_font_style;

        $container->append($tpl->as_html);
    }
}




__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=head1 NAME

Q1::Web::Widget::TagCloud

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
