package DBIx::Class::API::Types;

# predeclare our own types
use MooseX::Types -declare => [qw/

    HashKeysFromArray
    
    SortableColumns
    

/];

# import builtin types
use MooseX::Types::Moose qw/ ArrayRef HashRef Str /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Common::Numeric qw/PositiveInt/;


# generic type
subtype HashKeysFromArray, as HashRef;





# specific
subtype SortableColumns, as HashKeysFromArray;

coerce SortableColumns,
    from Str,       via { { $_ => 1 } },
    from ArrayRef,  via { 
        my %h;
    	map { $h{$_} = 1 } @$_;
    	\%h;
    };



1;


=head1 NAME

DBIx::Class::API::ConfigParams

=cut