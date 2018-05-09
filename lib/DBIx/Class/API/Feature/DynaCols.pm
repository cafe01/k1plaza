package DBIx::Class::API::Feature::DynaCols;

use Moose::Role;
use Scalar::Util qw/blessed/;
use namespace::autoclean;


has 'dynamic_columns'       => ( is => 'rw', isa => 'HashRef', predicate => 'has_dynamic_columns', clearer => '_clear_dynamic_columns' );
has 'dynamic_column_name'   => ( is => 'ro', isa => 'Str', default => 'dynamic_columns_store' );
has 'merge_dynamic_columns' => ( is => 'rw', isa => 'Bool', default => 1 );
has 'reset_dynamic_columns' => ( is => 'rw', isa => 'Bool', default => 1 );



# create
around '_prepare_create_object' => sub {
    my $orig = shift;
    my $self = shift;    
    my ($object) = @_;
    
    # no dynamic columns
    return $self->$orig(@_) unless $self->has_dynamic_columns;
    
    # extract dynamic columns
    my %dyn_cols;
    foreach (keys %{$self->dynamic_columns}) {
        if (exists $object->{$_}) {
            $dyn_cols{$_} = delete $object->{$_};
            $dyn_cols{$_} = "$dyn_cols{$_}" if blessed $dyn_cols{$_}; # stringify objects 
        }        
    }

    # run original
    my $item = $self->$orig($object);
    
    # plug to 'dynamic_columns_store' column    
    my $dyn_col_accessor = $self->dynamic_column_name;
    $item->{object}->$dyn_col_accessor(\%dyn_cols );
    
    $item;
};


# update
around '_prepare_update_object' => sub {
    my $orig = shift;
    my $self = shift;    
    my ($object) = @_;
    
    # no dynamic columns
    return $self->$orig(@_) unless $self->has_dynamic_columns;
    
    # extract dynamic columns
    my %dyn_cols;
    foreach (keys %{$self->dynamic_columns}) {
        if (exists $object->{$_}) {
            $dyn_cols{$_} = delete $object->{$_};
            $dyn_cols{$_} = "$dyn_cols{$_}" if blessed $dyn_cols{$_}; # stringify objects 
        }        
    }

    # run original
    my $item = $self->$orig($object);
    
    # update 'dynamic_columns_store' column    
    my $dyn_col_accessor = $self->dynamic_column_name;    
    my $current_dyna_cols = $item->{object}->$dyn_col_accessor;  
    $item->{object}->$dyn_col_accessor({ %$current_dyna_cols, %dyn_cols });
    
    $item;
};


# result
around 'result' => sub {
    my $orig = shift;
    my $self = shift;
    
    return $self->$orig(@_) unless $self->merge_dynamic_columns;
    
    $self->push_object_formatter(sub{
        my ($self, $object, $formatted) = @_;        
        my $serialized_column = $self->dynamic_column_name;
        
        return unless $object->has_column_loaded($serialized_column);
        
        # unfreeze column 
        unless (ref $formatted->{$serialized_column}) {
            $formatted->{$serialized_column} = $object->$serialized_column;
        }
        
        my $dyn_cols = delete $formatted->{$serialized_column};
        %$formatted = (%$formatted, %$dyn_cols);
    });   
    
    $self->$orig(@_);    
};

after 'reset' => sub {
    my $self = shift;
    $self->_clear_dynamic_columns if $self->reset_dynamic_columns;
};




1;

__END__
=pod

=head1 NAME

DBIx::Class::API::Feature::DynaCols

=head1 VERSION

Version 0.01

=head1 METHODS


=head1 DESCRIPTION

A moose role.

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

=cut