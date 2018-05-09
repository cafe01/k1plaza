package Q1::Utils::HTML::Excerpt;

use Moo;
use Types::Standard qw/ Int Bool /;
use namespace::autoclean;
use Carp;
use Q1::jQuery;

has 'min_frase_words' => ( is => 'rw', isa => Int, default => 3 );
has 'max_frases'      => ( is => 'rw', isa => Int, default => 3 );
has 'use_pagebreak'   => ( is => 'rw', isa => Bool, default => 1 );



sub excerpt {
	my ($self, $html_source, $options) = @_;

	return '' if (not defined $html_source or $html_source eq '');

	# set default options
	$options ||= $options;
	exists $options->{$_} or $options->{$_} = $self->$_
	   foreach qw/min_frase_words max_frases use_pagebreak/;

	# extract
	return $self->_extract_excerpt($html_source, $options);
}


sub _extract_excerpt {
    my ($self, $html_source, $options) = @_;
    my $excerpt = '';

    # using pagebreak
    #warn "SOURCE:\n$html_source\n\n";
    # my $pagebreak_match = qr/<!-- pagebreak -->/;
    # if ($options->{use_pagebreak} && $html_source =~ $pagebreak_match) {
    #     my $html = (split $pagebreak_match, $html_source)[0];
    #     #warn "EXTRACTED USING PB:\n$html\n";
    #     return _clean_html($html);
    # }

	# prepare source
	$html_source =~ s/&nbsp;/ /g;
	my $html = j($html_source);
	$html->find('p')->after('<br/>');
	$html->find('br')->replace_with('__NEWLINE_PLACEHOLDER__');

	my $text_content = $html->text;
	$text_content =~ s/\s*__NEWLINE_PLACEHOLDER__\s*/\n/g;

    # extract using frases
    my $max_frases      = $options->{max_frases}      || $self->max_frases;
    my $min_frase_words = $options->{min_frase_words} || $self->min_frase_words;

    my %re = (
       end_punctuation    => qr/(?:[.?!]+)/,
       # html_endfrase      => qr!(?:</?p>|</?span>|<br\s*/?\s*>|<img)!,
    );

    my $sentence_delimiter = qr!$re{end_punctuation}\K(\s+)(?=[A-Z])!;
    my @frases = split $sentence_delimiter, $text_content;
    # printf STDERR "(%d words) %s \n\n\n", _count_words($_), $_ for (@frases);

    # excerpt
    my $output = '';
	my $frases_count = 0;
    for (my $i = 0; $frases_count < $max_frases && $i < @frases; $i++) {

        if (_count_words($frases[$i]) >= $min_frase_words || $i == $#frases) {
            # push @excerpt, $frases[$i];
			$output .= $frases[$i];
			$frases_count++;
        }
        else {
            $frases[$i+1] = $frases[$i] . $frases[$i+1];
        }
    }

	# add newline
	$output =~ s/^\s+//;
	return $output;
}


sub _count_words {
    my $text = shift;
    my @num = $text =~ /(\S\s)/g;
    return @num ? @num + 1 : 0;
}



1;

__END__

=pod

=head1 NAME

Q1::Utils::HTML::Excerpt

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 min_frase_words

=head2 max_frases

=head2 use_pagebreak

=head1 METHODS

=head2 excerpt

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
