package Q1::Role::Widget::RenderSnippet;

use utf8;
use Moose::Role;
use namespace::autoclean;
use Carp;
use Digest::MurmurHash qw(murmur_hash);
use constant DEBUG_WIDGET => $ENV{DEBUG_WIDGET};
use Encode qw/encode/;


requires 'render_snippet';


has 'disable_html_cache', is => 'ro', isa => 'Bool', default => 0;


sub _build_html_cache_key {
    my ($self, $template) = @_;
    $self->_cache_key.':snippet:'.$template
}


# html cache
around 'render_snippet' => sub {
    my ($orig, $self) = (shift, shift);
    my $element = shift;
    my $data = shift // $self->data;

    my $tx = $self->tx;
    my $log = $tx->log;

    # default template
    $self->_load_element_template($element)
       if $element->children->size == 0;

    # html cache
    my $element_has_snippet = $element->xfind('.//*[@data-plift] | .//*[starts-with(name(), "x-")] | .//script[@data-plift-script]')->size > 0
        || $element->tagname =~ /^x-/;

    if ($element_has_snippet || $self->disable_html_cache || $self->cache_duration eq '0' || $self->cache_duration eq 'never') {
        # the $data arg should be undef to avoid calling get_data for cached html
        return $self->$orig($element, $data, @_);
    }


    my $cache = $self->tx->app->cache;
    my $key = 'widgethtml:'. murmur_hash($self->_build_html_cache_key(join  '', $element->as_html));

    if (my $html = $cache->get($key)) {
        $log->debug(sprintf "Using cached html for widget '%s':\n%s", ($self->name || ref $self), encode('utf8', $html)) if DEBUG_WIDGET;
        $html =~ /^\s*$/ ? $element->text($html) # html() calls new() which will die when no nodes are parsed
                         : $element->html($html);
    }
    else {
        $self->$orig($element, $data, @_);
        my $html = $element->html;
        $log->debug(sprintf "Caching html after render_snippet() for widget '%s':\n%s", ($self->name || ref $self), encode('utf8', $html)) if DEBUG_WIDGET;
        $cache->set($key, $html, $self->cache_duration);
    }

};





1;


__END__

=pod

=head1 NAME

Q1::Role::Widget::RenderSnippet

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
