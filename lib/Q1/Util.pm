package Q1::Util;

use 5.010;
require Exporter;
use Data::Dumper;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( shuffle pretty_format_duration );


sub shuffle
{
    my $array = shift;
    my $i = scalar @$array;
    return unless $i > 1;
    while ( --$i )
    {
        my $j = int rand( $i+1 );
        @$array[$i,$j] = @$array[$j,$i];
    }
}


sub pretty_format_duration {
    my ($duration) = @_;

    # find larger unit
    my $unit = 'seconds';
    foreach my $unit_name (qw/ minutes days months years /) {
        next unless $duration->$unit_name;
        $unit = $unit_name;
    }

    my $label = {
        seconds => ['segundo', 'segundos'],
        minutes => ['minuto', 'minutos'],
        days    => ['dia', 'dias'],
        months  => ['mês', 'mêses'],
        years   => ['ano', 'anos'],
    };

    sprintf "%d %s", $duration->$unit, $label->{$unit}[$duration->$unit == 1 ? 0 : 1];
}


1;

__END__

=encoding utf-8

=head1 NAME

Q1::Util

=head1 SYNOPSIS

    use Q1::Util;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@q1software.comE<gt>

=cut
