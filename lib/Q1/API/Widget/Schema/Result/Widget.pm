package Q1::API::Widget::Schema::Result::Widget;

use Q1::API::Media::Schema::Result::MediaCollection;
use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ IntrospectableM2M InflateColumn::Serializer Core /];




primary_column 'id' => {
   data_type => 'int',
   is_auto_increment => 1,   
};

column 'mediacollection_id' => {
    data_type => 'int',
    is_nullable => 1,
    is_foreign_key => 1  
};

column 'name' => {
    data_type => 'varchar',
    size      => 255,       
};

column 'class' => {
    data_type => 'varchar',
    size      => 255,       
};

column 'version' => {
    data_type => 'int',      
    default_value => 1,
    size => 16,
    extra => { unsigned => 1 }    
};

column 'is_initialized' => {
    data_type   => 'boolean',
    default_value => 0
};

belongs_to 'mediacollection' => 'Q1::API::Media::Schema::Result::MediaCollection', 'mediacollection_id', { cascade_delete => 1 };

Q1::API::Media::Schema::Result::MediaCollection->has_many( widgets => __PACKAGE__, 'mediacollection_id');


sub bump_version {
    my ($self) = @_;
    $self->update({ version => \'version + 1'});
    $self->discard_changes;
}




1;
__END__

=pod

=head1 NAME 

Q1::API::Widget::Schema::Result::Widget

=head1 DESCRIPTION

The 'widgets' table.

=head1 METHODS

=head2 insert

Sets the default value for 'config' (which is {}).

=cut
