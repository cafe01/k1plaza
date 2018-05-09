package Q1::Web::Widget::Links;

use utf8;
use Moose;
use namespace::autoclean;

extends 'Q1::Web::Widget';
with 'Q1::Role::Widget::DBICResource';

has '+template'     => ( default => 'widget/links.html' );
has '+backend_view' => ( default => 'links' );


sub _api_class { 'Links' }

sub render_snippet {
	my ($self, $element, $data) = @_;	

    # TODO load template if empty
    my $template = $element->find('.link-item')->first;

    return unless $template->size;
    

    foreach my $item (@{$data->{items}}) {
        my $tpl = $template->clone;
        
        # title
        $tpl->find('.link-title')->text($item->{title});
        
        # link
        $tpl->find('.link-link')->attr('href', $item->{url});
        
        $tpl->insert_before($template);        
    }
}




__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=head1 NAME

Q1::Web::Widget::Links

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head2 call

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut