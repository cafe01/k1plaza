package DBIx::Class::API::ConfigParams;

use Moose::Role;
use DBIx::Class::API::Types ':all';
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Common::Numeric qw/PositiveInt/;




=head1 NAME

DBIx::Class::API::ConfigParams

=cut


# common
has 'debug' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'resultset' => ( is => 'rw', isa => 'DBIx::Class::ResultSet' );

has 'dbic_class' => ( is => 'ro', isa => 'Str', lazy => 1, default => '' );

has 'app' => ( is => 'rw', isa => 'Object', weak_ref => 1 );

has 'auto_reset' => ( is => 'rw', isa => 'Bool', default => 1 );


has 'data_root'  => ( is => 'rw', isa => NonEmptySimpleStr, default => 'items' );
has 'total_key'  => ( is => 'rw', isa => NonEmptySimpleStr, default => 'total' );
has 'included_columns'  => ( is => 'rw', isa => 'ArrayRef', predicate => 'has_included_columns' );
has 'excluded_columns'  => ( is => 'rw', isa => 'ArrayRef', predicate => 'has_excluded_columns' );

has 'return_objects'   => ( is => 'rw', isa => 'Bool', default => 1 );


has 'return_inflated_columns'   => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub{ [] }
);


has 'use_json_boolean' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'default_object_formatter' => ( is => 'rw', isa => 'CodeRef', lazy_build => 1 );

has '_current_object_formatter' => ( is => 'rw', isa => 'CodeRef' );

has '_return_single_result' => ( is => 'rw', isa => 'Bool', default => 0 );



# list
has 'list_limit' => ( is => 'rw', isa => PositiveInt, default => 10 );

has 'default_list_order' => ( is => 'rw', isa => 'HashRef|ArrayRef|Str' );

has 'sortable_columns' => (
    traits  => ['Hash'],
    is  => 'ro',
    isa => SortableColumns,
    default => sub { {} },
    coerce => 1,
    lazy => 1,
    handles => {
        can_order_by         => 'exists',
        add_sortable_column  => 'set',
    },
);

# TODO implement option 'list_related', to automaticaly call with_related() before list()

# create
has 'create_forbids'=> ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );
has 'flush_object_after_insert' => (is => 'rw', isa => 'Bool', default => 0);

# update
has 'update_forbids'=> ( is => 'rw', isa => 'ArrayRef', lazy_build => 1 );






























1;
