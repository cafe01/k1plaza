package Q1::Web::Template::Plift::Filter::CurrentPage;

use utf8;
use Moo;
use namespace::autoclean;


has 'engine' => ( is => 'ro', required => 1, weak_ref => 1 );

sub process {
    my ($self, $doc) = @_;

    my $engine  = $self->engine;
    my $current_page = $engine->context;

    # lang
    $doc->find('html')->attr(lang => $engine->locale);

    # page title
    my $title = $doc->find('head > title');

    $title->text(sprintf "%s %s %s", $current_page->{title}, $title->attr('data-title-separator') || '-', $title->text)
        if $title->size && defined $current_page->{title};

    # page class
    if (defined $current_page->{fullpath}) {

        my $page_class = 'page-' . lc $current_page->{fullpath};
        $page_class =~ tr!/!-!;
        $doc->find('html, body')->add_class($page_class);
    }
}



1;


__END__

=pod

=head1 NAME

Q1::Web::Template::Plift::Filter::CurrentPage

=head1 DESCRIPTION

Add html related to the current page.

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
