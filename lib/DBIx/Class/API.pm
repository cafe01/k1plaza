package DBIx::Class::API;

use Moose;
use namespace::autoclean;
use Q1::Utils::Log;


with 'Q1::Role::Configurable';

with 'DBIx::Class::API::Core::List',
     'DBIx::Class::API::Core::Create',
     'DBIx::Class::API::Core::Update',
     'DBIx::Class::API::Core::Delete',
     'DBIx::Class::API::ConfigParams';

with 'MooseX::Clone';

has 'log' => ( is => 'rw', default => sub{ Q1::Utils::Log->new } );




has '_search_parameters' =>  (
    traits  => ['Array'],
    is => 'ro',
    isa  => 'ArrayRef',
    default => sub { [] },
    handles => {
        _clear_search_parameters => 'clear'
    }
);

has '_search_attributes' =>  (
    traits  => ['Hash'],
    is => 'ro',
    isa  => 'HashRef',
    default => sub { {} },
    handles => {
        _clear_search_attributes => 'clear',
        has_search_attribute     => 'exists',

    }
);

has '_objects' => (
    traits  => ['Array'],
    is => 'ro',
    isa  => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_objects => 'elements',
        add_object => 'push',
        count_objects => 'count',
        has_objects => 'count',
        _clear_objects => 'clear',
        get_object => 'get',
    }
);

has '_errors' => (
    traits  => ['Array'],
    is => 'ro',
    isa  => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_errors => 'elements',
        push_error => 'push',
        count_errors => 'count',
        has_errors => 'count',
        _clear_errors => 'clear',
    }
);

has '_object_formatters' => (
    traits  => ['Array'],
    is => 'ro',
    isa  => 'ArrayRef[CodeRef]',
    default => sub { [] },
    handles => {
        all_object_formatters    => 'elements',
        push_object_formatter    => 'push',
        add_object_formatter     => 'unshift',
        unshift_object_formatter => 'unshift',
        _clear_object_formatters => 'clear',
    }
);


has '_known_relationships' => ( is => 'rw', isa => 'ArrayRef', lazy_build => 1, clearer => '_clear_known_relationships' );


sub _build_default_object_formatter {
    sub {
        my ($self, $object, $formatted) = @_;

        my $visible_cols = $self->_visible_columns;

        # add columns found in the '+columns' attribute
        if ($self->_search_attributes->{'+columns'}) {
            $self->_search_attributes->{'+columns'} = [ $self->_search_attributes->{'+columns'} ]
                unless ref $self->_search_attributes->{'+columns'} eq 'ARRAY';

            foreach my $col (@{$self->_search_attributes->{'+columns'}}) {
                $col = (keys %$col)[0] if (ref $col);
                push @$visible_cols, $col;
            }
        }

        # get columns
        my %return_inflated_columns = map { $_ => 1 } @{ $self->return_inflated_columns };
        foreach (@$visible_cols) {
            #$self->log->debug("[i]\tformatting column '$_'");
            $formatted->{$_} = $return_inflated_columns{$_} ? $object->get_inflated_column($_)
                                                            : $object->get_column($_);
        }

        $formatted;
    }
}





sub _visible_columns {
    my ($self) = @_;
    my $source = $self->resultset->result_source;

    # start using all avaliable columns
    my %cols = map { $_ => 1 } $source->columns;

    # if "included_columns" is used, exclude columns not listed there
    if ($self->has_included_columns) {
        %cols = map {

            # die on bad config
            unless ($source->has_column($_)) {
                my $msg = sprintf("Bad 'included_columns' config. Source '%s' has no column named '%s'. What are you smoking?", $source->name, $_);
                $self->log->fatal($msg);
                die $msg;
            }

            $_ => 1;

        } @{ $self->included_columns };
    }

    # if "excluded_columns" is used, exclude columns listed there
    if ($self->has_excluded_columns) {
        foreach (@{ $self->excluded_columns }) {

            # die on bad config
            unless ($source->has_column($_)) {
                my $msg = sprintf("Bad 'excluded_columns' config. Source '%s' has no column named '%s'. What are you smoking?", $source->name, $_);
                $self->log->fatal($msg);
                die $msg;
            }

            unless (exists $cols{$_}) {
                $self->log->warn("Confuse 'excluded_columns' config. You excluded column '%s' but its not even on the included list. I'll ignore it, but you should check your config.");
            }

            delete $cols{$_};
        }
    }

    return [keys %cols];
}

sub _build__known_relationships {
    my ($self) = @_;
    my $source_class = $self->resultset->result_source;
    my $result_class = $self->resultset->result_class;
    my @rels = $source_class->relationships;
    push @rels, keys %{ $result_class->_m2m_metadata }
        if $result_class->can('_m2m_metadata');
    return \@rels;
}


sub _string_to_hash {
    my ($self, $string) = @_;
    confess "Default version of '_string_to_hash' method used! You MUST Implement this method in your subclass!";
}


=head2 BUILD

=cut

sub BUILD {
    my $self = shift;

    # auto-create resultset from 'schema' and 'dbic_class' config
    if (! $self->resultset && $self->app && $self->dbic_class ) {
        #$self->log->debug("[API] auto-creating resultset from 'dbic_class': ".$self->dbic_class);
        $self->resultset( $self->app->schema->resultset($self->dbic_class) );
    }
};


=head2 result

=cut

# TODO: return array of items in list context
sub result {
    my $self = shift;

    my $true  = $self->use_json_boolean ? \1 : 1;
    my $false = $self->use_json_boolean ? \0 : 0;

    my %result = ( success => $true );

    # has errors
    if ($self->has_errors) {
        $result{success} = $false;
        $result{errors}  = [ $self->all_errors ];
        return \%result;
    }

    # format objects
    $self->_current_object_formatter($self->default_object_formatter)
       unless $self->_current_object_formatter;

    my @formatted_objects;
    $self->unshift_object_formatter($self->_current_object_formatter);

    foreach my $object ($self->all_objects) {

        # resolve object
        $object = $object->{object} if ref $object eq 'HASH';

        # run all formatters
        my $formatted = {};
        $_->($self, $object, $formatted)
            foreach ($self->all_object_formatters);

        # push
        push @formatted_objects, $formatted;
    }

    # send objects
    $result{ $self->data_root } = $self->_return_single_result ? $formatted_objects[0] : \@formatted_objects;
#    $result{ $self->total_key } = $self->list_total_entries
#        if $self->has_list_total_entries;

    # when using pager
    # save total count, current page, and total pages
    if ( exists $self->_search_attributes->{page} ) {
        my $pager = $self->resultset->pager;
        $result{ $self->total_key } = $pager->total_entries;
        $result{$_}                 = $pager->$_ for qw/ current_page first_page last_page entries_per_page entries_on_this_page next_page previous_page /;
    }
    else {
        $result{ $self->total_key } = scalar(@formatted_objects);
    }

    return \%result;
}

# auto reset after: result, first, count
after [qw/ result first count /] => sub {
    my $self = shift;
    $self->reset if $self->auto_reset;
};





=head2 first

=cut

sub first {
    my ($self) = @_;
    return $self->has_objects ? $self->get_object(0) : ();
}



=head2 modify_resultset

=cut

sub modify_resultset {
    my ($self, $cond, $attrs) = @_;

    $self->resultset( $self->resultset->search_rs($cond, $attrs) );

    $self;
}



=head2 reset

Resets the api object.

- reset the resultset object. ( via $self->resultset->result_source->resultset )

=cut

sub reset {
    my ($self, $new_rs) = @_;

    #warn "Reseting API\n";

    $self->_clear_search_parameters;
    $self->_clear_search_attributes;
    $self->_clear_objects;
    $self->_clear_errors;
    $self->_clear_known_relationships;
    $self->_clear_object_formatters;
    $self->_return_single_result(0);

    $self->_flush_resultset($new_rs);

    $self;
}


sub _flush_resultset {
    my ($self, $new_rs) = @_;

    $self->resultset( $new_rs || $self->resultset->result_source->resultset );
    $self;
}


sub set_search_attribute {
    my ($self, $key, $val) = @_;
    $self->_search_attributes->{$key} = $val;
    $self;
}


__PACKAGE__->meta->make_immutable;





1;
