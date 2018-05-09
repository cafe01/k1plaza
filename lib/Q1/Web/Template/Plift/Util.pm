package Q1::Web::Template::Plift::Util;

use Exporter 'import';


 
@EXPORT_OK = qw(render_content);




sub render_content {
    my ($element, $content) = @_;

    my %render_at =  map { $_ => 1} split /\s*,\s*/, $element->attr('data-plift-render-at') || 'text';
        
    foreach my $key (keys %render_at) {
        
        # attr
        if ($key =~ /^@([\w-]+)/ ) {
            $element->attr($1, $content); # TODO escape correctly
            next;            
        }
        
        # must be text or html
        $key = lc $key;
        unless ($key eq 'text' || $key eq 'html' ) {
            $element->html('<div style="color:red"0>Opção inválida para o comando "data-plift-render-at": $key</div>');
            return;
        }        
        
        $key eq 'text' ? $element->text($content) : $element->html($content);
    }   

    
}












1;


__END__
=pod

=head1 NAME

Q1::Web::Template::Plift::Util

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut