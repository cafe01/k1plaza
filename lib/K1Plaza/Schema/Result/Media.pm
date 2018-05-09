package K1Plaza::Schema::Result::Media;


use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::API::Media::Schema::Result::Media',
    -components => ['Helper::Row::SubClass'];

subclass;



has_many 'mediacollection_medias' => 'K1Plaza::Schema::Result::MediaCollectionMedia', 'media_id';
many_to_many 'mediacollections' => 'mediacollection_medias', 'mediacollection';

1;

