package DBIx::Class::API::Feature::Sencha;

use utf8;
use Moo::Role;
use namespace::autoclean;
use Carp;
use JSON qw/ from_json /;
use Scalar::Util qw/ reftype /;

around 'list' => sub {
    my $orig = shift;
    my $self = shift;
    my ($params) = @_;
    
    $self->_apply_sencha_filters($params);
    $self->_apply_sencha_sorters($params);
            
    # query
    if ($params && reftype $params eq 'HASH' && $params->{query} && $self->can('_do_query')) {
        $self->_do_query($params->{query}, $params);
    }
    
    $self->$orig(@_);
};

sub _apply_sencha_filters {
    my ($self, $params) = @_;    
    return unless $params->{filter};
        
    my $filters = ref $params->{filter} ? $params->{filter} : from_json $params->{filter};
               
    foreach (@$filters) {
        $self->add_list_filter( $_->{property}, $_->{value} );
    }
}

sub _apply_sencha_sorters {
    my ($self, $params) = @_;
    return unless $params->{'sort'};
    
    my $sorters = ref $params->{sort} ? $params->{sort} : from_json $params->{sort};
        
    my @order_by;
    
    foreach (@$sorters) {       
        my $direction = $_->{direction} eq 'DESC' ? '-desc' : '-asc';
        push @order_by, { 
            $direction => $_->{property} 
        };        
    }
    
    $self->order_by(\@order_by) if @order_by;
}










1;


__END__

=pod

=head1 NAME

DBIx::Class::API::Feature::Sencha

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut