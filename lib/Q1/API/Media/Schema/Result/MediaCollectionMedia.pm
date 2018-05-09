package Q1::API::Media::Schema::Result::MediaCollectionMedia;

use strict;
use DBIx::Class::Candy -autotable => v1;


column 'mediacollection_id'   => { data_type => 'int' };
column 'media_id'             => { data_type => 'int' };

column 'position' => { data_type => 'int', default_value => 0 };
column 'weight'   => { data_type => 'int', default_value => 0 };

primary_key 'mediacollection_id', 'media_id';


sub insert {
    my $self = shift;
    
    $self->next::method(@_);
    
    if ($self->in_storage) {
        my $sql = sprintf '(SELECT * FROM (SELECT max(position)+1 FROM media_collection_medias WHERE mediacollection_id = %d) last_position)', $self->mediacollection_id;
        $self->update({ position => \$sql});
    }
    
    $self;
}


1;

__END__

=pod

=head1 NAME 

Q1::API::Media::Schema::Result::MediaCollectionMedia

=head1 DESCRIPTION

M2M link between Media and MediaCollection.

=head1 METHODS

=head2 insert

Sets the default value for 'position'.

=cut


