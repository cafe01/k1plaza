package Q1::Utils::Properties;



sub new {
    my $class = shift;

    bless {
        props => {}
    }, $class;
}


sub set {
    my $self = shift;
    $self->{props}->{$_} = 1 for map { lc } @_;
    $self;
}


sub unset {
    my $self = shift;
    delete @{$self->{props}}{map { lc } @_};
    $self;
}


sub clear {
    my $self = shift;
    %{$self->{props}} = ();
    $self;
}

sub get_all {
    my $self = shift;
    keys %{$self->{props}};
}



sub check {
    my $self = shift;
    # split each argument on comma or space, then trim ad lc keys
    my @keys = map { $_ =~ s/(^\s+|\s+$)//g; lc $_ } map { split /(?:,\s+|\s+)/ } @_;
    # warn sprintf "# keys: %s\n", join '|', @keys;
    foreach my $key (@keys) {
        return unless exists $self->{props}->{$key};
    }

    1;
}


sub check_any {
    my $self = shift;
    my @keys = map { $_ =~ s/(^\s+|\s+$)//g; lc $_ } map { split /(?:,\s+|\s+)/ } @_;
    # warn sprintf "# keys: %s\n", join '|', @keys;
    foreach my $key (@keys) {
        return 1 if exists $self->{props}->{$key};
    }

    return;
}


1;
