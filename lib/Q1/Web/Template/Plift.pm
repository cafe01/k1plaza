package Q1::Web::Template::Plift;

use utf8;
use Moo;
use Types::Standard qw/ ArrayRef HashRef Bool Str /;
use namespace::autoclean;
use Carp;
use URI;
use Data::Dumper;
use Devel::TimeStats;
use Class::Load;
use Mojo::File 'path';
use Try::Tiny;
use Q1::Web::Template::Plift::jQuery;
use Q1::Utils::Properties;

use constant {
    XML_DOCUMENT_NODE => 9,
    XML_DOCUMENT_FRAG_NODE => 11
};

our $VERSION = 0.1001;

has 'filters' => (
    is => 'rw',
    isa => ArrayRef,
    default => sub{ [] },
    trigger => \&_trigger_filters
);

has [qw/snippet_path filter_path/] => ( is => 'rw', isa => ArrayRef, default => sub{ [] } );
has 'static_path' => ( is => 'rw', isa => ArrayRef, default => sub{ [] }, trigger => _create_path_trigger('static_path') );
has 'include_path' => ( is => 'rw', isa => ArrayRef, default => sub{ [] }, trigger => _create_path_trigger('include_path') );
has 'javascript_include_path' => ( is => 'rw', isa => ArrayRef, default => sub{ [] }, trigger => _create_path_trigger('javascript_include_path') );
has 'sass_include_path' => ( is => 'rw', isa => ArrayRef, default => sub{[]} );
has 'context'      => ( is => 'rw', isa => HashRef, lazy => 1, default => sub{ {} } );
has 'environment'  => ( is => 'rw', isa => Str, default => 'production', lazy => 1 );
has 'locale'       => ( is => 'rw', isa => Str, default => '' );
has 'metadata_key' => ( is => 'rw', isa => Str, default => '__plift_meta' );

has 'enable_profiler' => ( is => 'rw', isa => Bool, default => sub{shift->debug}, lazy => 1 );
has 'debug', is => 'ro', isa => Bool, default => 0;

has 'profiler' => (
    is => 'rw',
    lazy => 1,
    #isa => 'Devel::TimeStats',
    predicate => 'has_profiler',
    default => sub{ Devel::TimeStats->new( enable => shift->enable_profiler )},
    clearer => 'reset_profiler'
);

has 'javascript_context' => (
    is => 'rw',
    predicate => 'has_javascript_context'
);

has 'properties', is => 'rw', lazy => 1, default => sub{ Q1::Utils::Properties->new };


sub metadata {
    my $self = shift;
    my $key = $self->metadata_key;
    my $data = $self->context;
    $data->{$key} = {} unless exists $data->{$key};
    $data->{$key};
}

sub process {
    my ($self, $template_name) = @_;

    $self->profile(begin => "template: $template_name");
    $self->profile(begin => "process template");

    # set properties
    $self->properties->set('locale.'.$self->locale, 'environment.'.$self->environment);

    # process
    my $document = $self->load_template($template_name);
    $self->process_element($document);
    $document = $document->document;

    # remove directives
    $document->xfind('//*[@'.$_.']')->remove_attr($_)
        for qw/ data-format-date data-plift-render-at/;

    # run filters
    $self->profile(end => "process template");
    $self->profile(begin => "apply filters");
    foreach my $filter (@{$self->filters}) {

        my $filter_class = ref $filter;
        my $is_code = $filter_class eq 'CODE';

        my $profiler_action = $is_code ? 'filter: <code>' : "filter: $filter_class";
        $profiler_action =~ s/Q1::Web::Template::Plift::Filter:://;
        $self->profile(begin => $profiler_action);

        if ($is_code) {
            $filter->($document, $self);
        }
        else {
            $filter->process($document, $self);
        }

        $self->profile(end => $profiler_action);
    }

    $self->profile(end => "apply filters");
    $self->profile(end => "template: $template_name");

    # dump profiler
    if ($self->enable_profiler) {
    #    print STDERR scalar $self->profiler->report;
    }

    $document;
}

sub run_snippet {
    my ($self, $snippet_name, $element, $params) = @_;

    my $snippet = $self->_instantiate_snippet($snippet_name, $params);

    my $is_code = ref $snippet eq 'CODE';
    my $profiler_action = $is_code ? 'snippet: <code>'
                                   : $snippet->can('profiler_action') ? $snippet->profiler_action
                                                                      : 'snippet: '.ref($snippet);

    $self->profile( begin => $profiler_action );

    my @args = ($element, $self, $params);
    if ($is_code) {
        my $console_data = ($self->context->{console} ||= []);
        my %console = map {
            my $cmd = $_;
            $cmd => sub { push @$console_data, [$cmd, @_] }
        } qw/ log info warn error /;
        $snippet->(@args, \%console);

        # replace x-tags by its content
        my $el = $args[0];

        $el->replace_with($el->contents)
            if $el->tagname =~ /^x-/;
    }
    else {
        $snippet->process(@args);
    }

    $self->profile( end => $profiler_action);
}


sub add_filter {
    my ($self, $filter, $filter_args) = @_;

    if (not ref $filter) {
        $filter = $self->_instantiate_filter($filter, $filter_args);
    }

    push @{$self->filters}, $filter;
}

sub _instantiate_filter {
    my ($self, $name, $args) = @_;
    $args ||= {};
    my @try_classes = map { $_ . '::' . $name } (@{ $self->filter_path }, 'Q1::Web::Template::Plift::Filter');
    my $filter_class = Class::Load::load_first_existing_class(@try_classes);
    $filter_class->new(%$args, engine => $self);
}

sub _trigger_filters {
    my ($self, $filters) = @_;
    @{$self->filters} = map { ref $_ ? $_ : $self->_instantiate_filter($_) } @$filters;
}

sub _create_path_trigger {
    my ($attr) = @_;
    sub {
        my ($self, $include_path) = @_;
        @{$self->$attr} = map { ref $_ ? $_ : path($_) } @$include_path;
    }
}

sub _get_new_id {
    my $self = shift;
    $self->{_last_id} ||= 1;
    return $self->{_last_id}++;
}


sub parse_html {
    my ($self, $source) = @_;
    j($source);
}

sub load_template {
    my ($self, $name, $document) = @_;

    # resolve template name to file
    my ($template_file, $try_files) = $self->find_template_file($name);
    die sprintf "Can't find a template file for template '%s', I tried:\n%s\n", $name, join(",\n", @$try_files)
        unless $template_file;

    # parse source
    my $handle = $template_file->open('<:encoding(UTF-8)');
    my $ret = my $html_source = '';
    while ($ret = $handle->read(my $buffer, 131072, 0)) { $html_source .= $buffer }
    die qq{Can't read from file "$template_file": $!} unless defined $ret;
    undef $handle;

    my $dom = $self->parse_html($html_source);

    # check for data-plift-template attr, and use that element
    my $body = $dom->find('body[data-plift-template]')->first;

    if ($body->size) {
        my $real_tpl_id = $body->attr('data-plift-template');
        $dom = $dom->find('#'.$real_tpl_id)->first;
        confess "Can't find element with id '$real_tpl_id' (referenced at <body data-plift-template=\"$real_tpl_id\">)."
            unless $dom->size;
    }

    # remove environment-bound elements
    my $doc = $dom->document;
    $doc->xfind('//*[@data-plift-environment]')->each(sub{
        $_->remove unless $_->attr('data-plift-environment') eq $self->environment;
        $_->remove_attr('data-plift-environment');
    });

    # remove properties-bound elements
    my $props = $self->properties;
    $doc->xfind('//*[@data-plift-remove-if]')->each(sub{
        $_->remove if $props->check($_->attr('data-plift-remove-if'));
        $_->remove_attr('data-plift-remove-if');
    });

    $doc->xfind('//*[@data-plift-remove-if-any]')->each(sub{
        $_->remove if $props->check_any($_->attr('data-plift-remove-if-any'));
        $_->remove_attr('data-plift-remove-if-any');
    });

    $doc->xfind('//*[@data-plift-remove-unless]')->each(sub{
        $_->remove unless $props->check($_->attr('data-plift-remove-unless'));
        $_->remove_attr('data-plift-remove-unless');
    });

    $doc->xfind('//*[@data-plift-remove-unless-any]')->each(sub{
        $_->remove unless $props->check_any($_->attr('data-plift-remove-unless-any'));
        $_->remove_attr('data-plift-remove-unless-any');
    });

    # remove locale-bound elements
    $doc->xfind('//*[@data-plift-locale]')->each(sub{
        $_->remove unless $_->attr('data-plift-locale') eq $self->locale;
        $_->remove_attr('data-plift-locale');
    });

    # adopt into document
    if ($document) {

        if ($dom->size && (my $dtd = $dom->get(0)->ownerDocument->internalSubset)) {
            $document->removeInternalSubset;
            $document->createInternalSubset( $dtd->getName, $dtd->publicId, $dtd->systemId );
        }

        my @nodes;
        for my $node (@{$dom->{nodes}}) {
            # dont adopt detached nodes
            next unless $node->getOwner->nodeType == XML_DOCUMENT_NODE;
            $document->adoptNode($node);
            push @nodes, $node;
        }

        $dom = j(\@nodes);
    }

    $dom;
}


sub find_template_file {
    my ($self, $template_name) = @_;
    my ($lang, $territory) = split /_|$/, $self->locale;
    $lang = lc $lang if $lang;
    $territory = uc $territory if $territory;

    my @try_files;

    foreach my $path (@{$self->include_path}) {

        push @try_files,
            $territory ? "$path/$template_name"."_$lang"."$territory.html" : (),
            $lang ? "$path/$template_name"."_$lang.html" : (),
            "$path/$template_name.html";
    }

    foreach my $file (@try_files) {
        return path($file) if -e $file;
    }

    wantarray ? (undef, \@try_files) : undef;
}


sub process_element {
    my ($self, $dom, $options) = @_;
    $options ||= {};

    my $doc = $dom->document;

    # find snippets
    my @mutators;
    my @wrappers;

    my $inflate = sub {

        my $el = $_;
        my $tag_name  = $el->tagname;
        my $is_xtag   = $tag_name =~ /^x-/;
        my $is_script = $tag_name eq 'script' || $tag_name eq 'x-script';

        # get snippet name and params
        my ($snippet_name, $snippet_params);

        if ($is_script) {

            $snippet_name  = 'script';
            my $description = $el->attr('description') || $el->attr('data-plift-script') || '';
            $snippet_params = {
                inline => 1,
                script_source => $el->text,
                $description ? (description => $description) : ()
            };
        }
        elsif ($is_xtag) {

            # snippet name from tag
            my $tag = $tag_name;
            ($snippet_name) = $tag =~ /^x-([\w\d-]+)/;

            confess "Template error: invalid <x-tag> element ($tag) missing snippet name after dash (x-foo)!"
               unless $snippet_name;

           # params from elements attrs
           $snippet_params = +{  map { $_->name => $_->value } $el->get(0)->attributes };
        }
        else {

            my $snippet_uri = URI->new($el->attr('data-plift'));
            $el->remove_attr('data-plift');

            confess "Template error: missing snippet name in the 'data-plift' attribute.! ($el)"
               unless $snippet_uri->path;

            $snippet_name = $snippet_uri->path;
            $snippet_params = { $snippet_uri->query_form };
        }

        # skip
        if ($options->{allowed_snippets} && $snippet_name !~ $options->{allowed_snippets}) {
            return 1;
        }

        # instantiate
        my $snippet = $self->_instantiate_snippet($snippet_name, $snippet_params);

        # enqueue
        my $queue = $snippet->can('deferred') && $snippet->deferred ? \@wrappers : \@mutators;
        push @$queue, [ $snippet, $el, $self, $snippet_params ];
    };

    $dom->xfilter('./*[@data-plift] | ./*[starts-with(name(), "x-")] | ./script[@data-plift-script]')
        ->add($dom->xfind('.//*[@data-plift] | .//*[starts-with(name(), "x-")] | .//script[@data-plift-script]'))
        ->each($inflate);

    # nothing to do
    # $self->profile('prepare snippets');
    return $doc unless (@mutators || @wrappers);

    # follow snippets
    foreach my $args (@mutators, reverse(@wrappers)) {

        my $snippet = shift @$args;
        my $profiler_action = $snippet->can('profiler_action') ? $snippet->profiler_action
                                                               : 'snippet: '.ref($snippet);

        if ($args->[0]->get(0)->getOwner->nodeType == XML_DOCUMENT_FRAG_NODE) {
            $self->profile("$profiler_action (skipped: element detached)");
            next;
        }

        $self->profile( begin => $profiler_action );
        $snippet->process(@$args);
        $self->profile( end => $profiler_action );
    }

    $doc;
}


sub _instantiate_snippet {
    my ($self, $snippet_name, $snippet_config) = @_;

    $snippet_config //= {};
    $snippet_config->{engine} = $self;

    my $snippet_class = try {
        $self->_resolve_snippet_class($snippet_name);
    }
    catch {
        # warn "_resolve_snippet_class() error: $_";
        # propagate errors other then "class not found"
        die $_ unless $_ =~ /^Can't locate [\w\s:,]+$snippet_name in \@INC/ ||
                      $_ =~ /is not a module name$/;
        0;
    };

    return $snippet_class->new($snippet_config)
        if $snippet_class;

    # no perl snippet class found, try javascript
    die "[Plift] template error: can't find (or can't load) snippet '$snippet_name'!\n"
        unless $self->has_javascript_context;

    # find javascript snippet
    my ($js_source, $js_path);

    foreach my $include_path (@{ $self->javascript_include_path}) {
        my $file = path("$include_path/$snippet_name.js");

        if (-f $file) {
            $js_source = $file->slurp;
            $js_path = "$file";
            last;
        }
    }

    # can't find javascript
    die "[Plift] template error: can't find snippet '$snippet_name'! (including javascript)\n"
        unless $js_source;

    # screate script snippet
    $self->_resolve_snippet_class('script')->new({
        script_source => $js_source,
        description => $js_path
    });
}

sub _resolve_snippet_class {
    my ($self, $name) = @_;
    my @try_classes = map { $_ . '::' . $name } (@{ $self->snippet_path }, 'Q1::Web::Template::Plift::Snippet');
    Class::Load::load_first_existing_class(@try_classes);
}


sub profile {
    my $self = shift;
    return unless $self->has_profiler;
    $self->profiler->profile(@_);
}



1;


__END__

=pod

=head1 NAME

Q1::Web::Template::Plift

=head1 DESCRIPTION

A Perl implementation of the liftweb view-first template system.

=head1 METHODS

=head2 process

=head1 X-TAGS

You can call a snippet using the <x-tag> syntax.

    <x-wrap with="layout" />

    <x-include path="footer" />

The string after x- is the snippet name, and the elements attributes are the parameters.

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
