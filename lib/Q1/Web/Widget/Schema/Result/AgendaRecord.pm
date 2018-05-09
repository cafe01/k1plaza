package Q1::Web::Widget::Schema::Result::AgendaRecord;

use strict;
use DBIx::Class::Candy
    -autotable => v1,
    -components => [qw/ TimeStamp Core /];



primary_column 'id' => {
    data_type      => 'int',
    is_auto_increment => 1,
};

column 'widget_id' => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};

column 'mediacollection_id' => {
    data_type => 'int',
    is_nullable => 1,
    is_foreign_key => 1

};

column 'title' => {
    data_type     => 'varchar',
    size          => 255,
};

column 'permalink' => {
    data_type   => 'varchar',
    size        => 255,
};

column 'content' => {
    data_type   => 'text',
    size => 65536
};

column 'excerpt' => {
    data_type   => 'text',
    size => 65536
};

column 'ticket_url' => {
    data_type     => 'varchar',
    size          => 512,
    default_value => "",
};

column 'venue' => {
    data_type     => 'varchar',
    size          => 512,
    default_value => "",
};

column 'location' => {
    data_type     => 'varchar',
    size          => 512,
    default_value => "",
};

column 'lat' => {
    data_type   => 'float',
    size        => '10,6',
    is_nullable => 1
};

column 'lng' => {
    data_type   => 'float',
    size        => '10,6',
    is_nullable => 1
};

column 'price' => {
    data_type   => 'decimal',
    size        => '10,2',
    is_nullable => 1
};

column 'is_published' => {
  data_type => 'boolean',
  default_value => 0,
};

column 'is_soldout' => {
  data_type => 'boolean',
  default_value => 0,
  is_nullable => 1
};

column 'is_canceled' => {
  data_type => 'boolean',
  default_value => 0,,
    is_nullable => 1
};

column 'is_free' => {
  data_type => 'boolean',
  default_value => 0,,
    is_nullable => 1
};

column date => {
    data_type     => 'datetime',
    timezone      => "UTC",
};




unique_constraint unique_permalink => [qw/ widget_id permalink /];

belongs_to 'mediacollection' => 'Q1::API::Media::Schema::Result::MediaCollection', 'mediacollection_id', { cascade_delete => 1, join_type => 'left', is_foreign_key_constraint => 0 };


sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => $sqlt_table->name.'_idx_'.'date', fields => ['date']);
}

sub insert {
    my $self = shift;

    my $has_mediacollection = $self->mediacollection_id;
    $self->mediacollection_id(undef) unless $has_mediacollection;

    $self->next::method(@_);

    if ($self->in_storage) {

        # create mediacollection
        unless ($has_mediacollection) {
            $self->mediacollection( $self->create_related('mediacollection', { app_instance_id => $self->app_instance_id }) );
            $self->update;
        }

        $self->discard_changes;
    }

    $self;
}





1;


__END__

=head1 NAME

Q1::Web::Widget::Schema::Result::AgendaRecord

=cut
