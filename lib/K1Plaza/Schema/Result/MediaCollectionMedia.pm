package K1Plaza::Schema::Result::MediaCollectionMedia;


use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::API::Media::Schema::Result::MediaCollectionMedia',
    -components => ['Helper::Row::SubClass'];

subclass;



belongs_to 'mediacollection' => 'K1Plaza::Schema::Result::MediaCollection', 'mediacollection_id', { is_foreign_key_constraint => 0 };
belongs_to 'media' => 'K1Plaza::Schema::Result::Media', 'media_id', { is_foreign_key_constraint => 0, cascade_delete => 1 };



1;

