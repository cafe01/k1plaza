package K1Plaza::AppInstance::PazEterna::API::Medicos;

use Moo;
use strict;
use warnings;
use namespace::autoclean;
use DateTime;
use utf8;
use Data::Printer;

use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);


has 'tx', is => 'ro';


has 'db', is => 'ro', lazy => 1, default => sub {
    shift->tx->api("EAV");
};

sub rs {
    my $self = shift;
    $self->db->resultset(shift);
}


sub list ($self, $params = {}) {
    my $limit = $params->{limit} ||= 10;
    my $page = $params->{page} ||= 1;
    my $offset = $page * $limit - $limit;

    my $cond = {};
    if (defined $params->{active} && length $params->{active}) {
        $cond->{active} = $params->{active} ? 1 : 0;
    }

    $cond->{"cidade"} = $params->{cidade}
        if $params->{cidade};

    $cond->{"especialidade"} = $params->{especialidade}
        if $params->{especialidade};

    $cond->{nome} = { -like => '%'.$params->{nome}.'%' }
        if $params->{nome};

    my $rs = $self->rs('Medico')->search($cond, {
        limit => $limit,
        offset => $offset,
        order_by => 'nome'
    });

    my @docs = map { $_->raw } $rs->all->@*;

    return {
        items => \@docs,
        total => $self->rs('Medico')->count($cond)
    }
}


sub list_aggregate ($self, $field, $cond = undef) {

    my $items = $self->rs('Medico')->search($cond, {
        'select' => [\"$field.value AS nome", { count => 'id', -as => 'sum' }],
        group_by  => [$field],
        order_by => $field
    })->cursor->all;

    $_->{nome} //= 'Não Preenchido' for @$items;

    $items;
}


sub find_by_id ($self, $id) {
    $self->rs('Medico')->find($id)
}


sub create ($self, $data = {}) {

    # format
    delete $data->{id};
    $data->{created_at} = DateTime->now;
    $data->{active} = $data->{active} ? 1 : 0;

    return { error => 'missing field' } unless $data->{nome};

    my $record = $self->db->resultset('Medico')->create($data);
    return $record ? { success => \1, id => $record->id, raw => $record->raw } : { success => \0 }
}

sub update ($self, $update = {}) {
    my $id = delete $update->{id} or die "Missing 'id' field.";
    my $record = $self->rs('Medico')->find($id) or return;
    $record->update($update);
    1;
}


sub delete ($self, $id) {
    my $record = $self->rs('Medico')->find($id) or return;
    $record->delete;
    1;
}





1;
