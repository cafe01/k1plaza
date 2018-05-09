package Q1::jQuery;

use strict;
use warnings;
use parent qw/Exporter/;
use Scalar::Util qw/ blessed /;
use XML::LibXML;
use HTML::Selector::XPath qw/selector_to_xpath/;
use Carp qw/ confess /;
use List::MoreUtils qw/ none distinct /;
use JSON::XS qw/ decode_json /;
use Mojo::Util qw/ decamelize /;



use constant {
    XML_ELEMENT_NODE            => 1,
    XML_TEXT_NODE               => 3,
    XML_COMMENT_NODE            => 8,
    XML_DOCUMENT_NODE           => 9,
    XML_DOCUMENT_FRAG_NODE      => 11,
    XML_HTML_DOCUMENT_NODE      => 13
};

our ($PARSER);
our @EXPORT = qw/ j /;

# for data()
my $data = {};

sub new {
    my ($class, $stuff, $before) = @_;
    $class = ref $class if ref $class;

    my $nodes;

    if (blessed $stuff) {

        if ($stuff->isa(__PACKAGE__)) {
            $nodes = $stuff->{nodes};
        }
        elsif ($stuff->isa('XML::LibXML::Element')) {
            $nodes = [$stuff];
        }
        else {
            confess "can't handle this type of object: ".ref $stuff;
        }
    }
    elsif (ref $stuff eq 'ARRAY') {

        $nodes = $stuff;
    }
    else {
        # parse as string
        if ($stuff =~ /^\s*<\?xml/) {
            die "xml parsing disabled!";
            $nodes = [ $PARSER->parse_string($stuff) ];
        } else {
            $nodes = [ _parse_html($stuff) ];
        }
    }

    if (@$nodes) {

        # increment document data refcount
        my $doc_id = $nodes->[0]->ownerDocument->unique_key;
        $data->{$doc_id}{refcount}++;
#        warn sprintf "[Document: %s] incrementing Q1::jQuery data ref count: %d\n", $doc_id, $data->{$doc_id}{refcount};

    }

    confess "undefined node" if grep { !defined } @$nodes;
    bless({ nodes => $nodes, before => $before }, $class);
}


#*j = \&jQuery;
sub j {
    __PACKAGE__->new(@_);
}

sub _parse_html {
    my $source = $_[0];

    if (!$PARSER){
        $PARSER = XML::LibXML->new();
        $PARSER->recover(1);
        $PARSER->recover_silently(1);
        $PARSER->keep_blanks(1);
        $PARSER->expand_entities(1);
        $PARSER->no_network(1);
#        local $XML::LibXML::skipXMLDeclaration = 0;
#        local $XML::LibXML::skipDTD = 0;
    }

    my $dom  = $PARSER->parse_html_string($source);
    my @nodes;


    # full html
    if ($source =~ /<html/i) {
        @nodes = $dom->getDocumentElement;
    }
    # html fragment
    elsif ($source =~ /<(?!!).*?>/) { # < not followed by ! then stuff until >    (match a html tag)
        @nodes = map { $_->childNodes } $dom->findnodes('/html/head | /html/body');
    }
    # plain text
    else {
        $dom->removeInternalSubset;
        @nodes = $dom->exists('//p') ? $dom->findnodes('/html/body/p')->pop->childNodes : $dom->childNodes;
    }

    confess "empy nodes :[" unless @nodes;
    confess "undefined node :[" if grep { ! defined } @nodes;
    # new doc (setDocumentElement accepts only element nodes)
    if ($nodes[0]->nodeType == XML_ELEMENT_NODE) {
        my $doc = XML::LibXML->createDocument;
        if ($source =~ /^\s*<!DOCTYPE/ && (my $dtd = $nodes[0]->ownerDocument->internalSubset)) {
            $doc->createInternalSubset( $dtd->getName, $dtd->publicId, $dtd->systemId );
        }
        $doc->setDocumentElement($nodes[0]);
        $nodes[0]->addSibling($_) foreach @nodes[1..$#nodes];
    }

    @nodes;
}


sub get {
    my ($self, $i) = @_;
    $self->{nodes}->[$i];
}

sub eq {
    my ($self, $i) = @_;
    $self->new([ $self->{nodes}[$i] || () ], $self);
}


sub end {
    shift->{before};
}

sub document {
    my $self = shift;
    $self->new([ $self->{nodes}[0] ? $self->{nodes}[0]->ownerDocument : () ], $self);
}

sub tagname {
    my $self = shift;
    return unless @{$self->{nodes}};
    $self->{nodes}[0]->localname;
}

sub first {
    my $self = shift;
    $self->new([ $self->{nodes}[0] || () ], $self);
}

sub last {
    my $self = shift;
    $self->new([ $self->{nodes}[-1] || () ], $self);
}

sub serialize {
    my ($self) = @_;
    my $output = '';

    $output .= $_->serialize
        for (@{$self->{nodes}});

    $output;
}


sub as_html {
    my ($self) = @_;

    my $output = '';

    foreach (@{$self->{nodes}}) {

        # TODO benchmark as_html() using can() vs nodeType to detect document nodes
        # best method, but only document nodes can toStringHTML()
        if ($_->can('toStringHTML')) {
            $output .= $_->toStringHTML;
            next;
        }

        # second best is to call toStringC14N(1), which generates valid HTML (eg. no auto closed <div/>),
        # but dies on some cases with "Failed to convert doc to string in doc->toStringC14N" error.
        # so we fallback to toString()
        {
            local $@; # protect existing $@
            my $html = eval { $_->toStringC14N(1) };
            $output .= $@ ? $_->toString : $html;
        }
    }

    $output;
}

sub html {
    my ($self, $stuff) = @_;

    # output
    unless ($stuff) {
        my $out = '';
        foreach my $node (map { $_->childNodes } @{$self->{nodes}}) {
            {
                local $@;
                my $html = eval { $node->toStringC14N(1) };
                $out .= $@ ? $node->toString : $html;
            }
        }
        return $out;
    }

    # replace content
    my $nodes = $self->new($stuff)->{nodes};

    foreach my $node (@{$self->{nodes}}) {
        $node->removeChildNodes;
        $node->appendChild($_->cloneNode(1)) for @$nodes;
    }

    $self;
}

sub text {
    my ($self, $stuff) = @_;

    # output
    unless (defined $stuff) {
        my $out = '';
        $out .= $_->textContent for @{$self->{nodes}};
        return $out;
    }

    # replace content
    return $self unless @{$self->{nodes}};

    my $textnode = $self->{nodes}[0]->ownerDocument->createTextNode($stuff);

    foreach my $node (@{$self->{nodes}}) {
        $node->removeChildNodes;
        $node->appendChild($textnode->cloneNode(1));
    }

    $self;
}


sub size {
    my ($self) = @_;
    scalar @{$self->{nodes}};
}

sub children {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => '.')
        if $selector;

    my @new = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () }
        map { $xpath ? $_->findnodes($xpath) : $_->childNodes }
        @{$self->{nodes}};

    $self->new(\@new, $self);
}

sub find {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => './');
    my @new = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () }
        map { $_->findnodes($xpath) }
        @{$self->{nodes}};

    $self->new(\@new, $self);
}

sub xfind {
    my ($self, $xpath) = @_;
    my @new = map { $_->findnodes($xpath) } @{$self->{nodes}};
    $self->new(\@new, $self);
}

sub filter {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => '.');
    my @new = map { _node_matches($_, $xpath) ? $_ : () }
        map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    $self->new(\@new, $self);
}

sub xfilter {
    my ($self, $xpath) = @_;

    my @new = map { _node_matches($_, $xpath) ? $_ : () }
        map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    $self->new(\@new, $self);
}

sub parent {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => '.')
        if $selector;

    my @new = map {

        !$xpath ? $_
                : _node_matches($_, $xpath) ? $_ : ()
    }
    grep { defined }
    map { $_->parentNode } @{$self->{nodes}};

    $self->new(\@new, $self);
}

sub clone {
    my ($self) = @_;
    my @new = map { $_->cloneNode(1) } @{$self->{nodes}};
    $self->new(\@new, $self);
}

sub _node_matches {
    my ($node, $xpath) = @_;
#    warn sprintf "# matching node: %s (%s)\n", ref $node, $node;
    foreach ($node->parentNode->findnodes($xpath)) {
#        warn sprintf "#     - against node: %s (%s)\n", ref $_, $_;
        return 1 if $_->isSameNode($node);
    }
    0;
}

sub add {
    my ($self, $stuff) = @_;
    my $nodes = $self->new($stuff)->{nodes};
    push @{$self->{nodes}}, @$nodes;
    $self;
}

sub each {
    my ($self, $cb) = @_;

    for (my $i = 0; $i < @{$self->{nodes}}; $i++) {

        local $_ = $self->new($self->{nodes}[$i]);
        my @rv = $cb->($i, $_);
        last if @rv == 1 && ! defined $rv[0];
    }

    $self;
}


sub append {
    my $self = shift;
    _append_to($self->new(@_)->{nodes}, $self->{nodes});
    $self;
}

sub append_to {
    my $self = shift;
    _append_to($self->{nodes}, $self->new(@_)->{nodes});
    $self;
}

sub _append_to {
    my ($content, $target) = @_;

    for (my $i = 0; $i < @$target; $i++) {

        my $is_last = $i == $#$target;
        my $node = $target->[$i];


        # thats because appendChild() is not supported on a Document node (as of XML::LibXML 2.0017)
        if ($node->isa('XML::LibXML::Document')) {

            foreach (@$content) {
                $node->hasChildNodes ? $node->lastChild->addSibling($is_last ? $_ : $_->cloneNode(1))
                                     : $node->setDocumentElement($is_last ? $_ : $_->cloneNode(1));
            }
        }
        else {
            $node->appendChild($is_last ? $_ : $_->cloneNode(1))
                for @$content;
        }
    }
}


sub prepend {
    my $self = shift;
    _prepend_to($self->new(@_)->{nodes}, $self->{nodes});
    $self;
}

sub prepend_to {
    my $self = shift;
    _prepend_to($self->{nodes}, $self->new(@_)->{nodes});
    $self;
}

sub _prepend_to {
    my ($content, $target) = @_;

    for (my $i = 0; $i < @$target; $i++) {

        my $is_last = $i == $#$target;
        my $node = $target->[$i];

        # thats because insertBefore() is not supported on a Document node (as of XML::LibXML 2.0017)
        if ($node->isa('XML::LibXML::Document')) {

            foreach (@$content) {
                $node->hasChildNodes ? $node->lastChild->addSibling($is_last ? $_ : $_->cloneNode(1))
                                     : $node->setDocumentElement($is_last ? $_ : $_->cloneNode(1));
            }

            # rotate
            while (not $node->firstChild->isSameNode($content->[0])) {
                my $first_node = $node->firstChild;
                $first_node->unbindNode;
                $node->lastChild->addSibling($first_node);

            }
        }

        # insert before first child
        my $first_child = $node->firstChild;
        $node->insertBefore($is_last ? $_ : $_->cloneNode(1), $first_child || undef) for @$content;
    }
}


sub before {
    my $self = shift;
    _insert_before($self->new(@_)->{nodes}, $self->{nodes});
    $self;
}

sub insert_before {
    my $self = shift;
    _insert_before($self->{nodes}, $self->new(@_)->{nodes});
    $self;
}

sub _insert_before {
    my ($content, $target) = @_;
    return unless @$content;

    for (my $i = 0; $i < @$target; $i++) {

        my $is_last = $i == $#$target;
        my $node = $target->[ $i ];
        my $parent = $node->parentNode;

        # content is cloned except for last target
        my @items = $i == $#$target ? @$content : map { $_->cloneNode(1) } @$content;

        # thats because insertAfter() is not supported on a Document node (as of XML::LibXML 2.0017)
        unless ($parent->isa('XML::LibXML::Document')) {

            $parent->insertBefore($_, $node) for @items;
            next;
        }

        # workaround for when parent is document:
        # append nodes then rotate until content is before node
        $parent->lastChild->addSibling($_) for @items;

        my $next = $node;
        while (not $next->isSameNode($items[0])) {
            my $node_to_move = $next;
            $next = $node_to_move->nextSibling;
            $parent->lastChild->addSibling($node_to_move);
        }
    }
}


sub after {
    my $self = shift;
    _insert_after($self->new(@_)->{nodes}, $self->{nodes});
    $self;
}

sub insert_after {
    my $self = shift;
    _insert_after($self->{nodes}, $self->new(@_)->{nodes});
    $self;
}

sub _insert_after {
    my ($content, $target) = @_;
    return unless @$content;

    for (my $i = 0; $i < @$target; $i++) {

        my $is_last = $i == $#$target;
        my $node = $target->[ $i ];
        my $parent = $node->parentNode;

        # content is cloned except for last target
        my @items = $i == $#$target ? @$content : map { $_->cloneNode(1) } @$content;

        # thats because insertAfter() is not supported on a Document node (as of XML::LibXML 2.0017)
        unless ($parent->isa('XML::LibXML::Document')) {

            $parent->insertAfter($_, $node) for @items;
            next;
        }

        # workaround for when parent is document:
        # append nodes then rotate next siblings until content is after node
        $parent->lastChild->addSibling($_) for @items;
#        warn "# rotating until $items[0] is after to $node\n";
        while (not $node->nextSibling->isSameNode($items[0])) {
            my $next = $node->nextSibling;
#            warn "#    - next: $next\n";
#            $next->unbindNode;
            $parent->lastChild->addSibling($next);
        }
    }
}


sub contents {
    my $self = shift;
    my @new = map { $_->childNodes } @{$self->{nodes}};
    $self->new(\@new, $self);
}

*detach = \&remove;

sub remove {
    my ($self, $selector) = @_;

    if ($selector) {
        $self->find($selector)->remove;
        return $self;
    }

    foreach (@{$self->{nodes }}) {
        # TODO test when there is no parent node
        $_->parentNode->removeChild($_);
    }

    $self;
}



sub replace_with {
    my ($self, $content) = @_;
    $content = $self->new($content)->{nodes}
        unless ref $content eq 'CODE';

    my $target = $self->{nodes};
    for (my $i = 0; $i < @$target; $i++) {

        my $node = $target->[ $i ];
        my $parent = $node->parentNode;
        my $final_content = $content;

        if (ref $content eq 'CODE') {
            local $_ = $self->new($node);
            $final_content = $content->($i, $_); # TODO check this callback signature
            $final_content = $self->new($final_content)->{nodes};
        }

        # no content, just remove node
        unless (@$final_content) {
            $parent->removeChild($node);
            delete $data->{$node->ownerDocument->unique_key}->{$node->unique_key};
            return $self;
        }

        # content is cloned except for last target
        my @items = $i == $#$target ? @$final_content : map { $_->cloneNode(1) } @$final_content;

        # on doc: append then rotate
        if ($parent->nodeType == XML_DOCUMENT_NODE) {

            $parent->lastChild->addSibling($_) for @items;
            while (not $node->nextSibling->isSameNode($items[0])) {
                $parent->lastChild->addSibling($node->nextSibling);
            }

            $parent->removeChild($node);
        }
        else {
            my $new_node = shift @items;
            $parent->replaceChild($new_node, $node);
            foreach (@items) {
                $parent->insertAfter($_, $new_node);
                $new_node = $_;
            }
        }

    }

    $self;
}

sub attr {
    my $self = shift;
    my $attr_name = shift;

    return unless defined $attr_name;

    # only element nodes
    my @nodes = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    # get
    return $nodes[0] ? $nodes[0]->getAttribute(lc $attr_name) : undef
        unless @_ || ref $attr_name;

    # set
    return $self unless @nodes;

    # set multiple
    if (ref $attr_name eq 'HASH') {

        foreach (@nodes) {
            while (my ($k, $v) = CORE::each %$attr_name) {
                $_->setAttribute($k, $v);
            }
        }

        return $self;
    }

    $attr_name = lc $attr_name;

    # from callback
    if (ref $_[0] eq 'CODE') {

        for (my $i = 0; $i < @nodes; $i++) {

            local $_ = $nodes[$i];
            my $value = $_[0]->($i, $_->getAttribute($attr_name));
            $_->setAttribute($attr_name, $value)
                if defined $value;
        }
    }
    else {
        $_->setAttribute($attr_name, $_[0])
            for @nodes;
    }

    $self;
}

sub remove_attr {
    my ($self, $attr_name) = @_;
    return $self unless defined $attr_name;

    $attr_name =~ s/(?:^\s*|\s$)//g;

    foreach my $node (map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}}) {
        foreach my $attr (split /\s+/, $attr_name) {
            $node->removeAttribute($attr);
        }
    }

    $self;
}


sub add_class {
    my ($self, $class) = @_;

    # only element nodes
    my @nodes = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    for (my $i = 0; $i < @nodes; $i++) {

        my $node = $nodes[$i];
        my $new_classes = $class;
        my $current_class = $node->getAttribute('class') || '';

        # from callback
        if (ref $class eq 'CODE') {
            local $_ = $self->new($node);
            $new_classes = $class->($i, $current_class);
        }

        my @current = split /\s+/, $current_class;
        $node->setAttribute('class', join ' ', distinct(@current, split /\s+/, $new_classes));
    }

    $self
}

sub remove_class {
    my ($self, $class) = @_;

    # only element nodes
    my @nodes = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    for (my $i = 0; $i < @nodes; $i++) {

        my $node = $nodes[$i];

        # remove all classes
        unless (defined $class) {
            $node->removeAttribute('class');
            next;
        }

        my $to_remove = $class;
        my $current_class = $node->getAttribute('class') || '';

        # from callback
        if (ref $class eq 'CODE') {
            local $_ = $self->new($node);
            $to_remove = $class->($i, $current_class);
        }

        my @current     = split /\s+/, $current_class;
        my @to_remove   = split /\s+/, $to_remove;

        my @new_classes;
        foreach  my $old (@current) {
            next unless none { $_ eq $old } @to_remove;
            push @new_classes, $old;
        };

        @new_classes > 0 ? $node->setAttribute('class', join ' ', @new_classes)
                         : $node->removeAttribute('class');
    }

    $self
}

sub data {
    my ($self, $key, $val) = @_;
    confess "data() is deprecated";
    # data()
    if (!defined $key) {

        # class method: return whole $data (mainly for test/debug)
        return $data unless ref $self;

        # instance method: return all data from first node
        my $node = $self->{nodes}[0];
        return unless $node;

        return ($data->{$node->ownerDocument->unique_key}->{$node->unique_key} //= {});
    }

    # no nodes
    return $self unless $self->{nodes}->[0];

    # data( obj )
    if (ref $key eq 'HASH') {
        # TODO die if not a HASH ref

        foreach my $node (@{$self->{nodes}}) {
            my $node_data = ($data->{$node->ownerDocument->unique_key}->{$node->unique_key} //= {});
            $node_data->{$_} = $key->{$_} for keys %$key;
        }

        return $self;
    }

    # data( key )
    if (! defined $val) {
        my $node = $self->{nodes}->[0];
        my $node_data = ($data->{$node->ownerDocument->unique_key}->{$node->unique_key} //= {});

        return $node_data->{$key} if defined $node_data->{$key};

        # try to pull from data-* attribute
        my $data_attr = 'data-'.decamelize($key);
        $data_attr =~ tr/_/-/;

        if ($node->nodeType == XML_ELEMENT_NODE && defined ($val = $node->getAttribute($data_attr))) {

            # convert

            # number
            if ($val =~ /^\d+$/) {
                $val += 0
            }
            # json array or object
            elsif ($val =~ /^(?:\{|\[)/) {
                {
                    local $@;
                    my $data = eval { decode_json $val };
                    $val = $data unless $@;
                }
            }
            # TODO boolean

            # save on data hash for next time
            $node_data->{$key} = $val;
        }

        return $node_data->{$key};
    }

    # data( key, val)
    foreach my $node (@{$self->{nodes}}) {
        my $node_data = ($data->{$node->ownerDocument->unique_key}->{$node->unique_key} //= {});
        $node_data->{$key} = $val;
    }

    return $self;
}



# decrement data ref counter, delete data when counter == 0
sub DESTROY {
    my $self = shift;

    my $node = $self->{nodes}[0];
    return unless $node;

    # decrement $data refcount
#     my $doc_id = $node->ownerDocument->unique_key;
#     $data->{$doc_id}{refcount}--;
# #    warn sprintf "[Document: %s] decrementing Q1::jQuery data ref count: %d\n", $doc_id, $data->{$doc_id}{refcount};
#
#     # delete document data if refcount is 0
#     delete $data->{$doc_id}
#         if $data->{$doc_id}{refcount} == 0;
}



1;

__END__

=head1 NAME

Q1::jQuery

=cut
