package Q1::Web::Widget::XMLFeed;

use namespace::autoclean;
use URI;
use XML::Feed;
use Q1::Moose::Widget;

extends 'Q1::Web::Widget';

has '+template'     => ( default => 'widget/xmlfeed' );
has '+cache_duration', default => '12h';

has_config 'url',         isa => 'Str', required => 1;
has_config 'max_entries', isa => 'Int', default => 10;



sub get_data {
    my ($self) = @_;
        
    my $res = $self->app->ua->get($self->url);
    
    unless ($res->is_success) {
        $self->cache_duration('1h');        
        return { error => 1, message => $res->status_line };
    }
        
    my $feed = XML::Feed->parse(\($res->content)) or warn "[XMLFeed] Error: ". XML::Feed->errstr;    
    
    my %data = map { $_ => $feed->$_ } qw/ title description author link base tagline language format copyright /;

    $data{items} = [map {
        my $entry = $_;                
        my $item = { map { $_ => $entry->$_ } qw/ title link base category tags author id issued modified / };
        $item->{$_} = $entry->$_->body for qw/ content summary /;
        $item;
    } $feed->entries];
    
    return \%data;     
}



sub render_snippet {
	my ($self, $e, $feed) = @_;
		
	if ($feed->{error}) {
	    my $msg = $self->tx->app_instance->environment eq 'development' ? sprintf '<div><!-- XMLFeed error: %s --></div>', $feed->{message} : ''; 
	    return $e->html($msg);
	}
    
    if ($e->children->size == 0) {
        $e->append('<ul><li class="feed-item"><a class="feed-item-link feed-item-title"></a></li>');
    }
    
    $e->find('.feed-'.$_)->text($feed->{$_})
        for qw/ title description author tagline /;

    my $tpl = $e->find('.feed-item');
    return $e->html('<div class="template-error" style="color:red; border:2px dashed red;">Erro: template não encontrado. (elemento com classe feed-item-link)</div>') 
        unless $tpl->size;    
    
    my $i = 0;
    foreach my $entry (@{$feed->{items}}) {       
        last if $i++ == $self->max_entries;
         
        my $item = $tpl->clone;
        $item->add_class("feed-item-$i")
              ->find('.feed-item-link')->attr(href => $entry->{link});
              
        $item->find('.feed-item-title')->text($entry->{title})
             ->end
             ->insert_before($tpl);
    }
    
    $tpl->remove;
}


1;

__END__

=pod

=head1 NAME 

Q1::Web::Widget::XMLFeed

=head1 DESCRIPTION

A proxy for xml web feeds.

=cut