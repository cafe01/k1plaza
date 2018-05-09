package Q1::Web::Template::Plift::Filter::Truncate;

#use utf8;
use Moo;
use Types::Standard qw/ ArrayRef HashRef Bool Str /;
use namespace::autoclean;

has 'engine' => ( is => 'ro', required => 1, weak_ref => 1 );


sub process {
    my ($self, $doc) = @_;
    my $engine = $self->engine;

    # Encontrar todos elementos com atributo data-plift-truncate
    $doc->find("[data-plift-truncate]")->each(sub {
        my $el = $_;

        # Get the truncate number
        my $truncate_number = $el->attr("data-plift-truncate");

        die "Non-numeric value on the data-plift-truncate attr."
            unless $truncate_number =~ /^\d+$/;

        # If the truncate number is less than the original content, than truncate it
        my $content = $el->text;

        if ($truncate_number < length($content)) {
            $content = substr($content, 0, $truncate_number - 3);
            $content .= "...";
        }

        # set text
        # $content = encode "UTF-8", $content;
        $el->text($content);


        # Delete the data-plift-truncate attr
        $el->remove_attr("data-plift-truncate");
    });

    $doc;
}



1;


__END__

=pod

=head1 NAME

Q1::Web::Template::Plift::Filter::Truncate

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Pedro Henrique da Cruz Torres - pedro_at_q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
