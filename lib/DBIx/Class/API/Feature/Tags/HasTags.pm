package DBIx::Class::API::Feature::Tags::HasTags;

use utf8;
use Moo::Role;
use namespace::autoclean;
use Carp;
use Q1::Utils::String qw/generate_permalink/;


sub with_tags {
    my $self = shift;
    $self->with_related('tags', undef, 1);
    $self
}

sub list_by_tag {
    my ($self, $name) = @_;

    my $rs = $self->resultset->result_source;
    my $relname = lc($rs->source_name).'_tags';

    die "Can't find relationship named '$relname'"
        unless $rs->has_relationship($relname);

    my $tag = $self->_get_tag_api->find({ slug => $name })->first;

    unless ($tag) {
        # NOTE: should this raise an api error?
        $self->push_error('unknown_tag');
        $self->log->info("[API] Unknown tag.");
        return $self;
    }

    $self->add_list_filter( $relname.'.tag_id' => $tag->id );
    $self->list;
}

sub _get_tag_api {
    my $self = shift;
    my $api_config = $self->does('Q1::API::Widget::TraitFor::API::BelongsToWidget')
                        ? { widget => $self->widget } : undef;

    $self->tx->api('Tag', $api_config)
}


sub _prepare_related_tags {
    my ($self, $raw) = @_;
    $raw = [$raw] unless ref $raw eq 'ARRAY';
    for (my $i = 0; $i < @$raw; $i++) {

        ref $raw->[$i]
            ? $raw->[$i]->{name} =~ s/^\s+|\s+$//g
            : $raw->[$i] =~ s/^\s+|\s+$//g;
    }

    my %tags = map { $_->id => $_ } @{ $self->_get_tag_api->find_or_create($raw) };
    [values %tags]
}




1;


__END__

=pod

=head1 NAME

DBIx::Class::API::Feature::Tags::HasTags

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
