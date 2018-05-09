package Q1::Web::Template::Plift::Snippet::meta;

use Mojo::Base -base;

sub process {
    my ($self, $element, $ctx) = @_;
    my $node = $element->get(0);
    my $meta = $ctx->metadata;

    # name/content pair
    if ($node->hasAttribute('name') && $node->hasAttribute('content')) {

        $meta->{$node->getAttribute('name')} = $node->getAttribute('content');
    }

    # attr=value pairs
    else {

        @$meta{keys %$node} = values %$node;
    }

    $node->unbindNode;
}






1;
