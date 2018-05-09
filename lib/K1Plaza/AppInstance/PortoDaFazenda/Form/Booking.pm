package K1Plaza::AppInstance::PortoDaFazenda::Form::Booking;

use utf8;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';


sub build_messages {
    return {
        required => 'Campo obrigatório.',
    };
}

has_field 'checkin'    => ( type => 'Text', label => 'Check In', required => 1 );
has_field 'checkout'    => ( type => 'Text', label => 'Check Out', required => 1 );
has_field 'adultos'    => ( type => 'Text', label => 'Adultos' );
has_field 'criancas'   => ( type => 'Text', label => 'Criancas' );
has_field 'suites'    => ( type => 'Text', label => 'Suítes' );
has_field 'nome'   => ( type => 'Text', label => 'Nome', required => 1 );
has_field 'telefone' => ( type => 'Text', label => 'Telefone', required => 1 );
has_field 'email' => ( type => 'Email', label => 'Email', required => 1 );

has_field 'submit'  => ( type => 'Submit', value => 'Enviar');
has_field '_csrf' => ( type => 'Hidden' );
has 'actions' => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );


sub _build_actions {
    return ['SendEmail'];
}


sub _build_basename {
	my @parts = split '::', ref shift;
	pop @parts;
}




no HTML::FormHandler::Moose;
1;

__END__

=pod

=head1 NAME

Q1::Web::Form::Contact

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head2 build_messages

Custom messages built here.

=head1 AUTHORS & COPYRIGHT

Pedro Cruz - pedro _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
