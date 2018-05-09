package Q1::Utils::String;

use 5.008008;
use strict;
use warnings;
use Unicode::Normalize;

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT = qw( generate_permalink );

our $VERSION = '0.01';



sub generate_permalink {
	my ($str, %opts) = @_;
	
	# max permalink length
    $opts{max_length} ||= 255;
    
    # lowecase it
    $str = lc $str;
         
    # replace by spaces: marks, ponctuations, symbols, separators, others (perl unicode tut)
    $str =~ s/(\pM|\pP|\pS|\pZ|\pC)/ /g;
    
    # trim
    $str =~ s/(^\s*|\s*$)//g;
    
    # replace space(s) by a dash
    $str =~ s/\pZ/-/g;
    $str =~ s/--+/-/g;    
    
    # normalize
    $str = Unicode::Normalize::NFKD($str);
    $str =~ s/\p{NonspacingMark}//g;
    
    # apply max length
    $str = substr($str, 0,  $opts{max_length});

    # add unique token
    if ($opts{add_unique_token}) {    
        $opts{max_token_length} ||= 9; # defaults to 9 digits (can handle up to 999999999 duplicated)        
        my $token = int(rand(9x$opts{max_token_length}));        
        $str = substr($str, 0,  $opts{max_length} - length($token) - 1); # make room for the token and a dash, ie. "-1234"
        $str = $str.'-'.$token;
    }

    return $str;
}





1;

__END__

=head1 NAME

Q1::Utils::String

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 generate_permalink($string, \%options)

Generates a string suitable for using as web resource permalink.

    my $permalink = generate_permalink('Some blog title!!!', { add_unique_token => 1 });
    
Valid options are:

    add_unique_token => Bool # adds a random number to the end of the permalink, usefull when the source string would result in a duplicated permalink
    
    max_length => PositiveInt # default 255, the maximum length of the generated permalink (accounting for the unique token)
    
    token_length => PositiveInt # default 9, the unique token length


=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut