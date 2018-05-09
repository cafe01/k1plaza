package DBIx::Class::API::Feature::Permalink;

use Moose::Role;
use namespace::autoclean;
use Q1::Utils::String qw/generate_permalink/;
use Scalar::Util qw(blessed reftype);

# TODO: write unit test for this class, currently being tested in the Blog widget test file

has 'permalink_column'        => ( is => 'ro', isa => 'Str', default => 'permalink' );
has 'permalink_source_column' => ( is => 'ro', isa => 'Str', default => 'title' );
has 'unique_permalink_constraint' => ( is => 'ro', isa => 'Str', default => 'unique_permalink' );

has 'generate_permalink_on_update', is => 'ro', default => 1;
has 'is_permalink_result', is => 'rw', default => 0, clearer => '_clear_is_permalink_result';



before 'list' => sub {
    my ($self, $args) = @_;

    $self->_clear_is_permalink_result;

    if (ref $args && reftype $args eq 'HASH' && defined $args->{$self->permalink_column}) {
        $self->modify_resultset({ 'me.'.$self->permalink_column => $args->{$self->permalink_column} });
        $self->is_permalink_result(1);
    }
};


around 'result' => sub {
    my $orig = shift;
    my $self = shift;

    my $result = $self->$orig(@_);
    $result->{is_permalink_result} = 1 if $self->is_permalink_result;
    $result;
};


around '_prepare_create_object' => sub {
    my $orig = shift;
    my $self = shift;
    my $object = shift;

    $object->{$self->permalink_column} = $self->_generate_permalink($object->{$self->permalink_source_column}, $object);

    $self->$orig($object);
};


around '_update_object' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        unless $self->generate_permalink_on_update;

    my ($item) = @_;
    my $object  = $item->{object};

    my $permalink_column        = $self->permalink_column;
    my $permalink_source_column = $self->permalink_source_column;

    $object->$permalink_column($self->_generate_permalink($object->get_column($permalink_source_column), $object))
        if $object->is_column_changed($permalink_source_column);

    $self->$orig(@_);
};


sub _generate_permalink {
    my ($self, $str, $object) = @_;

    my $clone_api = $self->clone;

    my $add_unique_token = 0;
    my $has_dup = 0;
    my $permalink;

    my $cols = blessed($object) ? {$object->get_columns} : $object;

    do {

        $clone_api->reset;
        $permalink = generate_permalink($str, add_unique_token => $add_unique_token++ );


        # my %cond = map { $_ => $cols->{$_} } $clone_api->resultset->result_source->unique_constraint_columns($self->unique_permalink_constraint);
        my %cond;
        $cond{$self->permalink_column} = $permalink;
        $has_dup = $clone_api->find(\%cond, { key => $self->unique_permalink_constraint })->first;

    } while ($has_dup);

    return $permalink;
}


sub find_by_permalink {
	my ($self, $permalink) = @_;
	$self->find({ 'me.'.$self->permalink_column => $permalink });
}


1;

__END__
=pod

=head1 NAME

Q1::Core::DBIx::Class:API::Feature::Permalink

=head1 VERSION

Version 0.01

=head1 METHODS

=head2 find_by_permalink($permalink)

=cut

=head1 DESCRIPTION

A moose role.

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

=cut
