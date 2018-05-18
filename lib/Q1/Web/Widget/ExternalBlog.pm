package Q1::Web::Widget::ExternalBlog;

use Q1::Moose::Widget;
use namespace::autoclean;
use URI;
use XML::Feed;
use Data::Dumper;
# use LWP::UserAgent;

extends 'Q1::Web::Widget';

has '+is_ephemeral', default => 1;
has '+cache_duration', default => '12h';


has_config 'url',         isa => 'Str', required => 1;
has_config 'max_entries', isa => 'Int', default => 10;

has_param 'limit', default => 0;

has 'tx', is => 'ro', required => 1;

# has 'ua' => (
#     is      => 'ro',
#     lazy    => 1,
#     default => sub {
#         LWP::UserAgent->new(
#             agent       => 'Q1Software Platform User-Agent',
#             timeout     => 10,
#             max_size    => 1024 * 1024 * 100,
#         )
#     }
# );


sub get_data {
    my ($self) = @_;

    # fetch feed url
    my $res = $self->tx->ua->get($self->url)->result;

    unless ($res->is_success) {
        $self->cache_duration('2m');
        $self->tx->log->error(sprintf "[ExternalBlog] GET '%s': %s %s", $self->url, $res->code, $res->message);
        return { success => \0, items => [], error => $res->message };
    }

    # parse feed
    my $feed = XML::Feed->parse(\($res->body));

    unless ($feed) {
        $self->tx->log->error("[ExternalBlog] XML::Feed error: ". XML::Feed->errstr);
        $self->cache_duration('30m');
        return { success => \0, items => [], error => XML::Feed->errstr };
    }

    my @items;

    foreach my $entry ($feed->entries) {
        my %post = map { $_ => $entry->$_ }  qw/ title link author /;
        map { $post{$_} = $entry->$_->body } qw/ content summary /;
        map { $post{$_} = $entry->$_ }  qw/ issued modified /;

        push @items, \%post;
    }

    return {
        success => \1,
        title   => $feed->title,
        items   => \@items
    }
}

sub render_snippet {
    my ($self, $element, $data) = @_;

    # limit
    splice(@{$data->{items}}, $self->limit)
        if $self->limit;

    # find template
    my $item_selector = '.blog-postlist-item, .blog-post-item';
    my $template = $element->find($item_selector)->first;
    unless ($template->size) {
        $element->html(sprintf '<h2 style="color:red">%s</h2>', "Template não encontrado! ($item_selector)");
        return;
    }

    # render
    my $item_schema = {
        title   => '.blog-post-title',
        author  => '.blog-post-author',
        issued  => { selector => '.blog-post-date', format_date => '%F %T' },
        summary => { selector => '.blog-post-excerpt', at => 'html' },
        content => { selector => '.blog-post-content', at => 'html' },
        link    => { selector => '.blog-post-link', at => '@href' }
    };

    my $schema = {
        title => '.blog-title',
        items => { selector => $item_selector, schema => $item_schema }
    };

    $element->render_data($schema, $data);
}


__PACKAGE__->meta->make_immutable;



__END__

=pod

=head1 NAME

Q1::Web::

=head1 DESCRIPTION



=cut
