package Q1::Web::Template::Plift::Snippet::widget;

use utf8;
use Moo;
use namespace::autoclean;
use Try::Tiny;
use Data::Dumper;
use Data::Printer;
use Carp qw/ confess /;
use Time::HiRes qw/time/;


has 'name', is => 'rw', lazy => 1, default => sub { shift->type };
has 'type', is => 'rw';
has 'engine', is => 'ro';


sub BUILD {
    my ($self) = @_;

    unless ($self->name) {
        my $tx = $self->engine->context->{tx};
        my $widget_name = $tx->arguments->{widget_args};

        die "[widget] missing param 'name' or 'type' (or the 'widget_args' page parameter)"
            unless $widget_name;

        $self->name($widget_name);
    }
}


sub profiler_action {
    'widget: '.shift->name;
}


sub process {
    my ($self, $element, $engine, $params) = @_;

    my %legacy_widgets = (
        Menu => 'menu',
        Breadcrumbs => 'breadcrumbs',
        Categories => 'categories',
        VimeoFeed => 'vimeo',
        Instagram => 'instagram',
    );

    if (my $snippet_name = $legacy_widgets{$self->name}) {
        # warn "# redirecting ${\ $self->name } widget to <x-$snippet_name>";
        return $engine->run_snippet($snippet_name, $element, $params);
    }

    my $tx = $engine->context->{tx};
    my %widget_config = %$params;
    delete @widget_config{qw/ engine name type is_page_widget arguments /};

    my ($widget, $error);
    try {
        $widget = $tx->widget($self->name, \%widget_config, \%widget_config, \%widget_config);
    }
    catch {
        $error = $_;
        $tx->log->error("[Q1::Web::Template::Plift::Snippet::widget] error: $error");
    };

    return $self->_error($element, $engine, sprintf "Erro ao executar widget '%s': %s\n", $self->name || $self->type, $error)
        if $error;

    # render
    try {
        $widget->render_snippet($element, $widget->does('Q1::Role::Widget::RenderSnippet') ? undef : $widget->data, $engine);
    }
    catch {
        $error = $_;
        $tx->log->error(sprintf "[Q1::Web::Template::Plift::Snippet::widget] widget '%s' error: %s", $self->name || $self->type, $error);

        die "Plift: widget->render_snippet error: $error"
            if $tx->app->mode eq 'development';

        $element->html(sprintf '<!-- erro ao executar widget "%s", os desenvolvedores ja foram notificados -->', $self->name || $self->type );
        $tx->send_system_alert_email('widget exception', sprintf "Class: %s\nName: %s\nError: %s", ref $widget, $widget->name, $error);
    };


    # x-tag
    $element->replace_with($element->contents)
        if $element->tagname =~ /^x-/;
}



sub _error {
    my ($self, $el, $engine, $msg) = @_;
    my $is_dev = $engine->environment eq 'development';
    $el->html($is_dev ? sprintf('<h2 style="color:red">%s</h2>', $msg) : '<!-- widget error -->');
}




1;


__END__
=pod

=head1 NAME

Q1::Web::Template::Plift::Snippet::widget

=head1 DESCRIPTION

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
