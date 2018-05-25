package K1Plaza::JS::Stash;

use strict;
use warnings;
use Hash::Util::FieldHash 'fieldhash';
use Data::Printer;

fieldhash my %c;

sub new {
    my ($class, $mojo_c) = @_;
    die "illegal" if ref $class;
    my $self = bless \( my $object ), $class;
    $c{$self} = $mojo_c;
    return $self;
}


sub get {
    my $self = shift;
    my $key = shift or return;
    die "Stash keys starting with __ are reserved for internal use."
        if $key =~ /^__/;
        
    $c{$self}->stash("$key");
}

sub set {
    my $self = shift;
    my $key = shift or return;
    die "Stash keys starting with __ are reserved for internal use."
        if $key =~ /^__/;

    $c{$self}->stash("$key", shift);
}


1;
