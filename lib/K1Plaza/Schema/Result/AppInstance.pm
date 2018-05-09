package K1Plaza::Schema::Result::AppInstance;


=head1 NAME

K1Plaza::Schema::Result::AppInstance

=cut

use DBIx::Class::Candy
    -autotable => v1,
    -base => 'Q1::API::AppInstance::Schema::Result::AppInstance',
    -components => [qw/ Helper::Row::SubClass /];


# subclass
subclass;



has_many 'acl_users' => 'K1Plaza::Schema::Result::AppInstance::ACL', 'app_instance_id';
many_to_many 'acls'  => 'acl_users', 'user';

__PACKAGE__->instance_has_many('users', 'K1Plaza::Schema::Result::User');
__PACKAGE__->instance_has_many('roles', 'K1Plaza::Schema::Result::Role');
__PACKAGE__->instance_has_many('categories', 'K1Plaza::Schema::Result::Category');
__PACKAGE__->instance_has_many('tags', 'K1Plaza::Schema::Result::Tag');
__PACKAGE__->instance_has_many('widgets', 'K1Plaza::Schema::Result::Widget');
__PACKAGE__->instance_has_many('medias', 'K1Plaza::Schema::Result::Media');
__PACKAGE__->instance_has_many('mediascollections', 'K1Plaza::Schema::Result::MediaCollection');
__PACKAGE__->instance_has_many('blog_posts', 'K1Plaza::Schema::Result::BlogPost');
__PACKAGE__->instance_has_many('expos', 'K1Plaza::Schema::Result::Expo');
__PACKAGE__->instance_has_many('links', 'K1Plaza::Schema::Result::Links');
__PACKAGE__->instance_has_many('agenda_records', 'K1Plaza::Schema::Result::AgendaRecord');

__PACKAGE__->instance_has_many('datas', 'K1Plaza::Schema::Result::Data');





1;
