package K1Plaza::Schema::Result::MediaCollection;

use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::API::Media::Schema::Result::MediaCollection',
    -components => ['Helper::Row::SubClass'];

subclass;


#__PACKAGE__->many2many('K1Plaza::Schema::Result::Media');


has_many 'mediacollection_medias' => 'K1Plaza::Schema::Result::MediaCollectionMedia', 'mediacollection_id';
many_to_many 'medias' => 'mediacollection_medias', 'media';

1;





__END__

=pod

=head1 NAME

K1Plaza::Schema::Result::MediaCollection

=cut
