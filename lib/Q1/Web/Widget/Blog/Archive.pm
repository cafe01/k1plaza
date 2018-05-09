package Q1::Web::Widget::Blog::Archive;

use utf8;
use namespace::autoclean;
use Q1::Moose::Widget;
use Encode 'encode';

extends 'Q1::Web::Widget';

# parent
has '+template', default => 'widget/blog_archive.html';
has '+is_ephemeral', default => 1;
has '+cache_duration', default => '12h';

# attributes
has '_blog_widget', is => 'rw', isa => 'Q1::Web::Widget::Blog', lazy_build => 1;

# config attributes
has_config 'blog_widget',       isa => 'Str',  default => 'blog', is_parameter => 1;
has_config 'expand_all',        isa => 'Bool', default => 0, is_parameter => 1;
has_config 'expand_last_year',  isa => 'Bool', default => 0, is_parameter => 1;
has_config 'expand_last_month', isa => 'Bool', default => 0, is_parameter => 1;
has_config 'include_excerpt',   isa => 'Bool', default => 0, is_parameter => 1;
has_config 'skip_empty_months', isa => 'Bool', default => 0, is_parameter => 1;
has_config 'locale',            isa => 'Str',  default => 'pt_BR', is_parameter => 1;


# for cache key
has_config '_blog_version' => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
        shift->_blog_widget->db_object->version;
    }
);

sub _build__blog_widget {
    my ($self) = @_;
    # TODO handle exception
    $self->tx->widget( $self->blog_widget );
}


sub get_data {
    my ($self, $tx) = @_;

    my $blog_widget = $self->_blog_widget;
    my $blog_api    = $tx->api('Blog');
    my $page_path   = $tx->stash->{fullpath} || 'blog';

    my $first_post = $blog_api->widget($blog_widget)->order_by({ -asc  => 'created_at' })->list->first;
    my $last_post  = $blog_api->widget($blog_widget)->order_by({ -desc => 'created_at' })->list->first;

    my @data;
    my $now = DateTime->now;

    # blog is empty
    return [] unless $first_post;

    # years
    foreach my $year ( reverse $first_post->created_at->year .. $last_post->created_at->year ) {

        my %year_data = (
            id => $year,
            label => $year,
            link => $tx->uri_for('/'.$page_path, [$year]).''
        );

        my $first_month = $year == $first_post->created_at->year ? $first_post->created_at->month : 1;
        my $last_month  = $year == $last_post->created_at->year  ? $last_post->created_at->month  : 12;

        # months
        foreach my $month (reverse $first_month .. $last_month ) {
            my $date = DateTime->new( year => $year, month => $month, time_zone => 'UTC', locale => $self->locale );

            my %month_data = (
                id => $month,
                label => $date->month_name,
                link => $tx->uri_for('/'.$page_path, [$year, sprintf('%02d', $month)]).''
            );

            # if expanded, fetch all posts
            if ( $self->expand_all || ($self->expand_last_month && $month == $last_month) ) {
                $month_data{items} = $self->_fetch_month($year, $month);
                $month_data{count} = scalar @{$month_data{items}};
            }
            else {
                $month_data{count} = $blog_api->widget($blog_widget)
                                              ->modify_resultset({ -and => [\[ 'YEAR(me.created_at) = ?', $year ], \[ 'MONTH(me.created_at) = ?', $month ]]})
                                              ->count;
                $month_data{items} = [];
            }

            # skip_empty_months
            next if $self->skip_empty_months && $month_data{count} == 0;

            # push
            push @{ $year_data{items} }, \%month_data;
            $year_data{count} += $month_data{count};
        }

        push @data, \%year_data;
    }

    return \@data;
}

sub _fetch_month {
    my ( $self, $year, $month ) = @_;

    my $blog_widget = $self->tx->widget( $self->blog_widget );
    my $blog_api    = $self->tx->api('Blog');

    my $result = $blog_api->widget($blog_widget)->list({ year => $year, month => $month })->result;

    my @cols = qw/ title permalink year month day /;
    push @cols, 'excerpt' if $self->include_excerpt;

    my @posts;
    foreach my $post (@{$result->{items}}) {
        my %post = map { $_ => $post->{$_} } @cols;
        push @posts, \%post;
    }

    return \@posts;
}


sub render_snippet {
    my ($self, $element, $data) = @_;

    $self->_load_element_template($element)
       if $element->children->size == 0;

    # year tpl
    my $tpl_year = $element->find('.blog-archive-year-item')->first;
    if ($tpl_year->size) {

        my $schema = {
            label => '.blog-archive-year-label',
            link  => { '.blog-archive-year-link' => '@href' },
            items => {
                selector => '.blog-archive-month-item',
                callback => sub {
                    my ($tpl, $tpl_data) = @_;
                    $self->_render_months($tpl, $tpl_data);
                }
            }
        };

        $tpl_year->render_data($schema, $data);

        return;
    }

    # months
    my $tpl_month = $element->find('.blog-archive-month-item')->first;
    return $element->html('<div style="color:red; border: 2px dashed red;">ERRO: Blog::Archive template não encontrado (.blog-archive-year-item ou .blog-archive-month-item)</div>')
        unless $tpl_month->size;

    $self->_render_months($tpl_month, $self->_flatten_years);
}

sub _flatten_years {
    my $self = shift;
    my $data = $self->data;
    my @months;

    foreach my $year (@$data) {
        push @months, map {

            $_->{year_id} = $year->{id};
            $_->{year_label} = $year->{label};
            $_->{year_count} = $year->{count};
            $_->{year_link} = $year->{link};
            $_;

        } @{$year->{items}};
    }

    \@months;
}

sub _render_months {
    my ($self, $tpl, $data) = @_;
    my $tx = $self->tx;
    my $current_page_path = $tx->stash->{fullpath};

    my $schema = {
        label => '.blog-archive-month-label',
        count => '.blog-archive-month-post-count',
        link  => { '.blog-archive-month-link' => '@href' },
        year_label => '.blog-archive-year-label',
        year_link  => { '.blog-archive-year-link' => '@href' }
    };

    $tpl->render_data($schema, $data);
}




# sub _old_render_snippet {
#     my ($self, $element, $data) = @_;
#     my $tx = $self->tx;
#
#     $self->_load_element_template($element)
#        if $element->children->size == 0;
#
#     # year tpl
#     my $year_template  = $element->find('.blog-archive-year-item')->first;
#     return $element->html('<div style="color:red; border: 2px dashed red;">ERRO: Blog::Archive template não encontrado (class="blog-archive-year-item")</div>')
#         unless $year_template->size;
#
#     my $current_page_path = $tx->stash->{fullpath};
#
#     foreach my $year (@$data) {
#
#         #$app->log->debug('# Year: '. $year->{label});
#         my $year_tpl = $year_template->clone;
#
#         $year_tpl->find('.blog-archive-year-label')->text($year->{label});
#         $year_tpl->find('.blog-archive-year-link')->attr(href => $tx->uri_for('/'.join '/', $current_page_path, $year->{id}));
#
#         # months
#         my $month_template  = $year_tpl->find('.blog-archive-month-item')->first;
#         next unless $month_template->size;
#
#         foreach my $month (@{$year->{items}}) {
#
#             my $month_tpl = $month_template->clone;
#             #$app->log->debug('#  month: '. $month->{label});
#
#             $month_tpl->find('.blog-archive-month-label')->text($month->{label});
#             $month_tpl->find('.blog-archive-month-post-count')->text($month->{count});
#             $month_tpl->find('.blog-archive-month-link')->attr(href => $tx->uri_for('/'.join '/', $current_page_path, $year->{id}, sprintf('%02d', $month->{id})));
#
#             # post list
#             my $post_template  = $month_tpl->find('.blog-archive-post-item')->first;
#             next unless $post_template->size;
#
#             foreach my $post (@{$month->{items}}) {
#
#                 #$app->log->debug('    post: '. $post->{title});
#                 my $post_tpl = $post_template->clone;
#
#                 $post_tpl->find('.blog-archive-post-title')->text(encode 'utf8', $post->{title});
#                 $post_tpl->find('.blog-archive-post-link')->attr(href => $post->{url});
#
#                 $post_tpl->insert_before($post_template);
#             } # end of post list
#
#             $post_template->remove;
#
#             $month_tpl->insert_before($month_template);
#         }   # end of months
#
#         $month_template->remove;
#
#         $year_tpl->insert_before($year_template);
#     } # end of years
#
#     $year_template->remove;
# }




__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

Q1::Web::Widget::Blog::Archive

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
