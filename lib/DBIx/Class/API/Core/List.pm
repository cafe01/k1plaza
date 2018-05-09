package DBIx::Class::API::Core::List;

use Moose::Role;
use Carp;
use Data::Dumper;
use Scalar::Util qw/ reftype /;

# TODO rename to _search_condition
has '_list_filters' =>  (
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    handles => {
        _clear_list_filters => 'clear',
        add_list_filter => 'set',
    }
);



has 'list_total_entries' => (
    is => 'rw',
    isa => 'Int',
    clearer   => '_clear_list_total_entries',
    predicate => 'has_list_total_entries',
    );




# make methods return a reference to $self
around [qw/ add_list_filter _clear_list_filters /] => sub {
    my $orig = shift;
    my $self = shift;
    $self->$orig(@_);
    $self;
};



=head2 reset

- clear list filters

=cut

before 'reset' => sub {
    my ($self) = @_;

    $self->_clear_list_filters;
    $self->_clear_list_total_entries;
};



sub where {
    my $self = shift;
    confess "odd number of arguments supplied to where()" unless scalar(@_) % 2 == 0;

    $self->add_list_filter(shift, shift)
        while (scalar @_);

    $self;
}


=head2 order_by

=cut

sub order_by {
    my ($self, $order_by) = @_;

    $order_by = $self->_validate_order_by($order_by);
    return $self unless scalar @$order_by > 0;

    push @{$self->_search_attributes->{'order_by'}}, $order_by;
    $self;
}

sub group_by {
    my ($self, @cols) = @_;
    $self->_search_attributes->{'group_by'} = \@cols;
    $self;
}

sub having {
    my ($self, $value) = @_;
    confess "undefined value given to having()" unless defined $value;
    $self->_search_attributes->{'having'} = $value;
    $self;
}


=head2 _validate_order_by

Check if the order_by clause is listed in 'sortable_columns'.

Can test simple string values (eg. 'colname') or hashref like { -asc|-desc => 'colname' }.

=cut

sub _validate_order_by {
    my ($self, $order_by_raw) = @_;
    $order_by_raw = ref $order_by_raw eq 'ARRAY' ? $order_by_raw : [$order_by_raw];

    my $is_valid;
    my @order_by;
    foreach my $order_by (@$order_by_raw) {

        if (ref $order_by eq 'SCALAR') {
            push @order_by, $order_by;
            next;
        }

        $order_by = { -asc => $order_by } unless ref $order_by;
        $order_by = [%$order_by];

        unless ($order_by->[1] =~ /\./) {
            $order_by->[1] = "me." . $order_by->[1];
        }

        $is_valid = $self->can_order_by($order_by->[1]);

        unless ($is_valid) {
            $self->log->warn("Invalid order_by column: ".$order_by->[1]);
            next;
        }

        push @order_by, { @$order_by };
    }

    return \@order_by;
}


=head2 page

=cut

sub page {
    my ($self, $page, $limit) = @_;
    $page ||= 1;
    $self->set_search_attribute( page => $page );
    $self->limit($limit) if $limit;
    $self->limit($self->list_limit) unless $self->has_search_attribute('rows');
    $self;
}


=head2 limit

Sets the 'rows' search attribute to $limit or $self->list_limit. Only used by the L<list> operation.

    $api = $api->limit( $positive_int );

=cut

# TODO: rename 'list_limit' config attr
sub limit {
    my ($self, $limit) = @_;
    confess "Undefined limit!" unless defined $limit;
    $self->set_search_attribute( rows => $limit );
    $self;
}


=head2 offset

Sets the 'offset' search attribute to $offset. Only used by the L<list> operation.

    $api = $api->offset( $positive_int );

=cut

sub offset {
    my ($self, $offset) = @_;
    die "Undefined offset!" unless defined $offset;
    $self->set_search_attribute( offset => $offset );
    $self;
}







=head2 find

Arguments: any search condition accepted by DBIx::Class::ResultSet::find.

=cut

sub find {
    my ($self, $cond, $attrs) = @_;
    $attrs ||= {};

    # prepare
    $self->_prepare_read;

    # fetch
    my $object = $self->resultset->find($cond, { %{$self->_search_attributes}, %$attrs });

    # prepare object for result or emit error
    $self->_return_single_result(1);
    if ($object) {
        $self->add_object($object);
    }
#    else {
#        $self->log->warn("Couldn't find() database object. (condition: @cond)");
#        $self->push_error("Couldn't find() database object.");
#    }

    $self;
}


=head2 _prepare_read

=cut

sub _prepare_read {
    my ($self) = @_;

    # clear objects
    $self->_clear_objects;

    # apply filters
    $self->_list_apply_filters;

    # select columns
    $self->_list_select_columns;

    # default order
    if ($self->default_list_order && not ($self->resultset->is_ordered || $self->has_search_attribute('order_by'))) {
        $self->order_by($self->default_list_order, 1);
    }

    # perform search
    $self->modify_resultset($self->_search_parameters, $self->_search_attributes);
}


=head2 count

Calls prepare_read, then return the sql count().

=cut

sub count {
    my ($self, @args) = @_;
    $self->_prepare_read;
    $self->resultset->count(@args);
}



=head2 list

The list operation is split in parts: ...


=cut

sub list {
    my ($self, $params) = @_;

    if (ref $params && reftype $params eq 'HASH') {

        # page
        $self->page($params->{page}, $params->{limit})
            if $params->{page};
    }

    # prepare
    $self->_prepare_read;

    # save objects
    $self->add_object($self->resultset->all);

    $self;

}




sub _list_select_columns {
    my ($self) = @_;

    $self->set_search_attribute( columns => $self->_visible_columns );

    $self;
}


sub _list_apply_filters {
    my ($self) = @_;

    my $cond    = {};
    my $attrs   = $self->_search_attributes;
    my $filters = $self->_list_filters;


    my %join_rels;

    # ensure the 'join' attibute is undefined or an arrayref
    if ($attrs->{join}) {
        $attrs->{join} = ref $attrs->{join} eq 'ARRAY' ? $attrs->{join}
                                                       : [ $attrs->{join} ];
    }

    while (my ($col, $value) = each %$filters) {

        # with filter modifiers
        if ($col =~ /(\w+):(.*)/) {

            # filter modifier and col
            my $mod = $1;
            $col = $2;

            $value = { '>=' => $value } if ($mod eq 'min');
            $value = { '<=' => $value } if ($mod eq 'max');
            $value = { '-like' => '%' . $value . '%' } if ($mod eq 'like');
        }

        # related col
        # TODO validate relationship and foreign col exists and are exposed
        # TODO expand m2m rels
        # TODO call method to resolve unknown rel
        if ($col =~ /\./) {
            my ($rel_name) = split /\./, $col;
            $join_rels{$rel_name} = 1;
        }
        else {
            # not related col, add 'me.' to avoid ambiguity
            $col = "me.$col"
                if $self->resultset->result_source->has_column($col);

        }

        # set condition
        $cond->{$col} ||= [ '-and' ];
        push @{$cond->{$col}}, $value;
    }


    # push join relationships
    $self->join(keys %join_rels);

    # apply filter conditions
    $self->modify_resultset($cond);
}


=head2 join

=cut

sub join {
    my ($self, @joins) = @_;

    my $attrs   = $self->_search_attributes;

    # ensure the 'join' attibute is undefined or an arrayref
    if ($attrs->{join}) {
        $attrs->{join} = ref $attrs->{join} eq 'ARRAY' ? $attrs->{join}
                                                       : [ $attrs->{join} ];
    }

    # push join relationships
    push @{$attrs->{join}}, @joins;


    $self;
}


=head2 prefetch

=cut

sub prefetch {
    my ($self, @prefetchs) = @_;
    my $attrs   = $self->_search_attributes;

    # ensure the 'prefetch' attibute is undefined or an arrayref
    if ($attrs->{prefetch}) {
        $attrs->{prefetch} = ref $attrs->{prefetch} eq 'ARRAY' ? $attrs->{prefetch}
                                                               : [ $attrs->{prefetch} ];
    }

    # push prefetch relationships
    push @{$attrs->{prefetch}}, @prefetchs;

    $self;
}


=head2 with_related($rel_name, \@rel_columns, $no_prefetch)

=cut

sub with_related {
    my ($self, $rel_name, $rel_columns, $no_prefetch) = @_;

    my $source_class = $self->resultset->result_source;
    my $result_class = $self->resultset->result_class;

    my $rel_info = $result_class->relationship_info($rel_name);
    if (!$rel_info && $result_class->can('_m2m_metadata')) {
        $rel_info = $result_class->_m2m_metadata->{$rel_name}
    }

    #use Data::Dumper;
    #warn Dumper($rel_info);

    confess "Cant find information for relationship '$rel_name' found!" unless $rel_info;

    my ($rel_type, $accessor, $foreign_accessor, $prefetch);

    if (exists $rel_info->{attrs} && $rel_info->{attrs}->{accessor} eq 'multi') {
        $rel_type = 'has_many';
        $accessor = $prefetch = $rel_name;
    }
    elsif (exists $rel_info->{attrs} && $rel_info->{attrs}->{is_foreign_key_constraint}) {
        $rel_type = 'belongs_to';
        $accessor = $prefetch = $rel_name;
    }
    elsif (exists $rel_info->{foreign_relation}) {
        $rel_type = 'm2m';
        $accessor = $rel_info->{relation};
        $foreign_accessor =  $rel_info->{foreign_relation};
        $prefetch = { $rel_info->{relation} => $rel_info->{foreign_relation}};
    }
    else {
        confess "Can't find relationship type from \$rel_info! WTF!!??!?!";
    }

    $self->prefetch($prefetch) unless $no_prefetch;

    $self->add_object_formatter(sub{
        my ($self, $object, $formatted) = @_;

        my @data;
        if ($rel_type eq 'm2m') {
            foreach ($object->$accessor) {
                push @data, $_->$foreign_accessor;
            }
        }
        else {
           @data = grep { defined } $object->$accessor;
        }

        my @formatted;
        foreach my $rel_obj (@data) {
            my %cols = $rel_columns ? map { $_ => $rel_obj->has_column($_) ? $rel_obj->get_column($_) : $rel_obj->$_ } @$rel_columns
                                    : $rel_obj->get_columns;

            push @formatted, \%cols;
        }

        if ($rel_type eq 'belongs_to') {
            $formatted->{$rel_name} = $formatted[0];
        } else {
            $formatted->{$rel_name}          = \@formatted;
            $formatted->{$rel_name.'_count'} = @formatted;
        }
    });

    $self;
}

=pod

many_to_many = {
          'remove_method' => 'remove_from_roles',
          'set_method' => 'set_roles',
          'relation' => 'map_user_role',
          'add_method' => 'add_to_roles',
          'rs_method' => 'roles_rs',
          'foreign_relation' => 'role',
          'accessor' => 'roles'
        };


belongs_to = {
          'cond' => {
                      'foreign.artistid' => 'self.artist'
                    },
          'source' => 'MyDatabase::Main::Result::Artist',
          'attrs' => {
                       'is_foreign_key_constraint' => 1,
                       'undef_on_null_fk' => 1,
                       'accessor' => 'filter'
                     },
          'class' => 'MyDatabase::Main::Result::Artist'
        };


has_many = {
          'cond' => {
                      'foreign.artist' => 'self.artistid'
                    },
          'source' => 'MyDatabase::Main::Result::Cd',
          'attrs' => {
                       'join_type' => 'LEFT',
                       'cascade_copy' => 1,
                       'cascade_delete' => 1,
                       'accessor' => 'multi'
                     },
          'class' => 'MyDatabase::Main::Result::Cd'
        };


=cut




1;
