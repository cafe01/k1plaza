package Q1::Web::Widget::Schema::Result::Expo;

use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ IntrospectableM2M InflateColumn::Serializer TimeStamp Core/];


primary_column 'id' => {
   data_type => 'int',
   is_auto_increment => 1,
};


column widget_id => {
    data_type       => 'integer',
    is_foreign_key  => 1,
};

column mediacollection_id => {
    data_type => 'int',
    is_nullable => 1,
    is_foreign_key => 1

};

column locale => {
    data_type => 'char',
    is_nullable => 1,
    size => 5
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

column position => {
    data_type   => 'int',
    size        => 255,
    default_value => 0,
};

column metadata => {
    data_type           => 'text',
    serializer_class    => 'JSON',
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


belongs_to 'mediacollection' => 'Q1::API::Media::Schema::Result::MediaCollection', 'mediacollection_id', { cascade_delete => 1, join_type => 'left', is_foreign_key_constraint => 0 };


sub insert {
    my $self = shift;

    my $has_mediacollection = $self->mediacollection_id;
    $self->mediacollection_id(undef) unless $has_mediacollection;

    $self->metadata({}) unless $self->has_column_loaded('metadata');

    $self->next::method(@_);

    if ($self->in_storage) {
        my $sql = sprintf '(SELECT * FROM (SELECT max(position)+1 FROM expoes WHERE widget_id = %d) last_position)', $self->widget_id;

        # create mediacollection
        unless ($has_mediacollection) {
            $self->mediacollection( $self->create_related('mediacollection', { app_instance_id => $self->app_instance_id }) );
        }

        $self->update({ position => \$sql});

        $self->discard_changes;
    }

    $self;
}

# TODO wtf is this doing? nothing ah? delete it!
sub delete {
    my $self = shift;

    my $mediacollection_id = $self->mediacollection_id;

    my $rv = $self->next::method(@_);

    $rv;
}

1;


__END__

=pod

=head1 NAME

Q1::Web::Widget::Schema::Result::Expo

=head1 DESCRIPTION

Expo result class.

=head1 METHODS

=head2 insert

Sets the default value for 'position'.

=head2 delete

Doing nothing!!!?! Check it!

=cut
