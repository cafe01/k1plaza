package K1Plaza::JS::Console;

use strict;
use warnings;
use Hash::Util::FieldHash 'fieldhash';
use Mojo::Util qw/ decode /;
use JSON::XS;

fieldhash my %c;

my $JSON = JSON::XS->new->pretty;



sub new {
    my ($class, $mojo_c) = @_;
    my $self = bless \( my $object ), $class;
    $c{$self} = $mojo_c;
    return $self;
}

my $format = sub {
    return map { 
               ref $_ ? $JSON->encode($_) 
                      : (decode('UTF-8', $_) || $_)
           }            
           map { defined $_ ? $_ : 'undef' } 
           @_;
};


sub log {
    shift->debug(@_);
}

sub debug {
    my $self = shift;
    $c{$self}->log->debug($format->(@_));
}

sub info {
    my $self = shift;
    $c{$self}->log->info($format->(@_));
}

sub warn {
    my $self = shift;
    $c{$self}->log->warn($format->(@_));
}

sub error {
    my $self = shift;
    my @lines = $format->(@_);
    $c{$self}->log->error(@lines);
    return $lines[0]; # useful to concatenate on throw
}




1;
