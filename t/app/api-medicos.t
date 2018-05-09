use Test::K1Plaza;

app->home(Mojo::Home->new("."));
app->api('EAV')->schema->deploy(add_drop_table => 1);


my $c = app->build_controller;
my $api =  app->api('AppInstance');
($c->stash->{__app_instance}) = $api->_instantiate_app_instance($api->register_app('PazEterna'));




isa_ok $c->api('Medicos'), 'K1Plaza::AppInstance::PazEterna::API::Medicos';



subtest 'create' => sub {

    my $api = $c->api('Medicos');
    my $res = $api->create({ nome => 'Carlos Fernando', cidade => 'Vix', especialidade => 'Geral' });
    like $res, { id => qr/\w+/, success => \1 };

    my $record = $api->db->resultset('Medico')->find({ nome => 'Carlos Fernando' });
    is $record->get('nome'), 'Carlos Fernando', 'nome';
    is $record->get('cidade'), 'Vix', 'cidade';
    is $record->get('especialidade'), 'Geral', 'especialidade';
    like $record->get('created_at'), qr/\d{4}-\d\d-\d\d \d\d:\d\d:\d\d/, 'created_at';

};

subtest 'list' => sub {

    my $api = $c->api('Medicos');
    like $api->list->{items}, [{
        nome => 'Carlos Fernando',
        id => qr/\w+/,
        active => 0
    }];
};

subtest 'list_aggregate' => sub {

    my $api = $c->api('Medicos');
    my $rs = $api->rs('Medico');
    $rs->delete;
    $rs->create({ nome => 'Joao', cidade => 'Vix' });
    $rs->create({ nome => 'Maria', cidade => 'Vix' });
    $rs->create({ nome => 'Pedro', cidade => 'Guarapari' });
    $rs->create({ nome => 'Cafe' });

    my $cidades = $api->list_aggregate('cidade');
    # p $cidades;
    is $cidades, [
        { nome => 'Não Preenchido', sum => 1 },
        { nome => 'Guarapari', sum => 1 },
        { nome => 'Vix', sum => 2 },
    ];

};

subtest 'update' => sub {

    my $api = $c->api('Medicos');
    $api->rs('Medico')->delete;
    my $res = $api->create({ nome => 'Joao', cidade => 'Vix' });
    ok $api->update({ id => $res->{id}, active => 1 });
    is $api->rs('Medico')->find({nome => 'Joao'})->get('active'), 1, 'updated';

};

subtest 'delete' => sub {

    my $api = $c->api('Medicos');
    my $res = $api->create({ nome => 'Pedro', cidade => 'Vix' });
    ok $api->delete($res->{id});
    is $api->rs('Medico')->count({id => $res->{id}}), 0, 'deleted';

};


done_testing();
