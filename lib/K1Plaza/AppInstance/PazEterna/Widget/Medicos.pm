package K1Plaza::AppInstance::PazEterna::Widget::Medicos;

use namespace::autoclean;
use Data::Dumper;
use Q1::Moose::Widget;
use Mojo::Promise;
use Data::Printer;
extends 'Q1::Web::Widget';


has_param 'limit', default => 100, is_config => 1;
has_param 'cidade', lazy => 1, default => sub { shift->tx->param('cidade') };
has_param 'especialidade', lazy => 1, default => sub { shift->tx->param('especialidade') };
has '+cache_duration', default => 0;

sub load_fixtures {
    my $self = shift;
    my $api = $self->tx->api('Medicos');
    $self->tx->log->debug("Loading fixtures for 'Medicos'");
    $api->create({
        nome => 'Fulano de Tal'.$_,
        telefone => '(27) 3262-520'.$_,
        especialidade => 'Clinico Geral',
        endereco => 'Rua Tira Dentes nº'.$_,
        endereco_2 => 'Ed. Comercial Tropical Center',
        bairro => 'Bairro'.$_,
        cidade => 'Cidade'.$_,
        estado => 'ES',
    }) for (1..25);
}


sub get_data {
    my ($self, $tx) = @_;
	my $api = $tx->api('Medicos');

    my %params = (
        active => 1,
        limit => $self->limit,
        cidade => $self->cidade,
        especialidade => $self->especialidade
    );

    my $res = {
        items  => $api->list(\%params)->{items},
        cidades => $api->list_aggregate('cidade', { active => 1 }),
        especialidades => $api->list_aggregate('especialidade'),
    };

    if ($self->cidade) {
        map { $_->{selected} = 'selected' if $_->{nome} eq $self->cidade }
            @{$res->{cidades}};
    }

    if ($self->especialidade) {
        map { $_->{selected} = 'selected' if $_->{nome} eq $self->especialidade }
            @{$res->{especialidades}};
    }

    $res;
}


sub render_snippet {
    my ($self, $element, $data) = @_;

    my %schema = map {
        my $selector = ".$_";
        $selector =~ tr/_/-/;
        $_ => $selector;
    } qw/ nome telefone especialidade endereco endereco_2 bairro cidade estado /;

    $element->find('.medico-item')->render_data(\%schema, $data->{items});

    # cidades
    $element->find('select#cidades option:last-child')->render_data({
        nome  => '.',
        value => { xpath => '.', at => '@value', data_key => 'nome' },
        selected => { xpath => '.', at => '@selected' },
    }, $data->{cidades});

    # especialidades
    $element->find('select#especialidades option:last-child')->render_data({
        nome  => '.',
        value => { xpath => '.', at => '@value', data_key => 'nome' },
        selected => { xpath => '.', at => '@selected' },
    }, $data->{especialidades});

}



__PACKAGE__->meta->make_immutable();

1;
