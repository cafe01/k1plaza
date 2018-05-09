package Q1::Web::API::Payment::Schema::Payment;

use strict;
use DBIx::Class::Candy -components => [qw/ TimeStamp InflateColumn::Serializer Core /];


table 'payments';


primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};

unique_column 'reference' => {
    data_type     => 'char',
    size          => 32,
};

column 'user_id' => {
    data_type       => 'integer',
    is_nullable => 1,
    is_foreign_key  => 1,
};

column 'provider_id' => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};

column 'status_id' => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};


column 'sender_name' => {
    data_type     => 'varchar',
    size          => 255,
};

column 'sender_email' => {
    data_type     => 'varchar',
    size          => 255,
};

column 'account' => {
    data_type     => 'varchar',
    size          => 255,
};

column 'currency' => {
    data_type     => 'char',
    size          => 6,
};

column 'amount' => {
    data_type   => 'decimal',
    size        => '10,2',
};

column 'metadata' => {
    data_type        => 'text',
    serializer_class => 'JSON',
    is_nullable      => 1
};

column 'created_at' => {
    data_type     => 'datetime',
    set_on_create => 0,
    set_on_update => 0,
    timezone      => "UTC",
};



sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => $sqlt_table->name.'_idx_'.'created_at', fields => ['created_at']);
}



1;


__END__
