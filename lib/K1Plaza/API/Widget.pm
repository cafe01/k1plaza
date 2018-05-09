package K1Plaza::API::Widget;

use Moose;
use namespace::autoclean;

extends 'Q1::API::Widget';
with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';

__PACKAGE__->config(
    use_json_boolean => 1,
);


1;

sub bump_version {
    my ($self, $widget_name) = @_;
    $self->resultset->update({ name => $widget_name, version => \'version + 1' });
}





__PACKAGE__->meta->make_immutable();





__END__

=pod

=head1 NAME

K1Plaza::API::Widget

=head1 DESCRIPTION

=head1 Reordering

Arguments: $widget_id $src_media_id, $target_media_id

1. Encontrar midias pelo id
2. If moving up:

update table
    Set ListOrder = ListOrder + 1
        where ListOrder >= $target_position
            and ListOrder < $src_position

 update MyTable
     Set ListOrder= $target_position -- The New Position
         Where Bookmark='f

3. If moving down:

update table
    Set ListOrder = ListOrder - 1
        where ListOrder <= $target_position
            and ListOrder > $src_position

 update table
     Set ListOrder= $target_position -- The New Position
         Where Bookmark='f

=cut
