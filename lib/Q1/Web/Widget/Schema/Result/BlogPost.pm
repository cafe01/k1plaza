package Q1::Web::Widget::Schema::Result::BlogPost;

use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ IntrospectableM2M TimeStamp Core/];

=head1 NAME

Q1::Web::Widget::Schema::Result::BlogPost

=cut


primary_column 'id' => {
   data_type => 'int',
   is_auto_increment => 1,
};


column widget_id => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};

column author_id => {
    data_type       => 'integer',
    is_nullable     => 1, # mostly for fixtures
    is_foreign_key  => 1,
};

column is_published => {
  data_type => 'boolean',
  default_value => 0,
};

column title => {
    data_type   => 'varchar',
    size        => 255,
};


column permalink => {
    data_type   => 'varchar',
    size        => 255,
};


column content => {
    data_type   => 'text',
    size => 65536,
};

column excerpt => {
    data_type   => 'text',
    size => 65536,
};

column thumbnail_url => {
    data_type   => 'varchar',
    size        => 1024,
    default_value => ''
};

column has_manual_thumbnail => {
    data_type     => 'boolean',
    default_value => 0,
};


column created_at => {
    data_type     => 'datetime',
    set_on_create => 1,
    set_on_update => 0,
    timezone      => "UTC",
};


column updated_at => {
    data_type     => 'datetime',
    set_on_create => 1,
    set_on_update => 1,
    timezone      => "UTC",
};


unique_constraint unique_permalink => [qw/ widget_id permalink /];


#has_many 'comments' => 'MyApp::Schema::Result::BlogComment', 'owner_id';

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(
        name   => $sqlt_table->name.'fulltext',
        fields => ['title','content'],
        type   => 'FULLTEXT'
    );
}


1;
