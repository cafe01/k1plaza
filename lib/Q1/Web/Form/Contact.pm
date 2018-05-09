package Q1::Web::Form::Contact;

use utf8;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';


sub build_messages {
    return {
        required => 'Campo "[_1]" é obrigatório.',
        email_format => 'Digite o e-mail no formato nome@exemplo.com',
    };
}



has_field 'name'    => ( type => 'Text', label => 'Nome', wrapper_class => 'field' );
has_field 'email'   => ( type => 'Email', label => 'Email', wrapper_class => 'field' );
has_field 'phone'   => ( type => 'Text', label => 'Telefone', inactive => 1, wrapper_class => 'field' );
has_field 'birthday'   => ( type => 'Text', label => 'Aniversário', inactive => 1, wrapper_class => 'field' );
has_field 'subject' => ( type => 'Text', label => 'Assunto', wrapper_class => 'field' );
has_field 'message' => ( type => 'TextArea', label => 'Mensagem', required => 1, wrapper_class => 'field' );
has_field 'submit'  => ( type => 'Submit', value => 'Enviar', wrapper_class => 'field' );


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

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
