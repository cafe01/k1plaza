package DBIx::Class::Helper::Many2Many;

use strict;
use warnings;
#use Moose;
#use namespace::autoclean;
#use base 'DBIx::Class';

use Class::Load ();
use Lingua::EN::Inflect ();

=head1 NAME

DBIx::Class::Helper::Many2Many

=head1 DESCRIPTION

=cut

#DBIx::Class::Candy
#DBIx::Class::Relationship::Base


=head2 many2many

=cut

sub many2many {
    my ($class, $related_class) = @_;

    # use case:
    #
    # MyApp::Schema::Result::Video->many2many('MyApp::Schema::Result::Tag');

    # generate names
    my ($namespace, $this_entity) = $class =~ /(.*::)(.*)/; # MyApp::Schema::Result and Video
    my ($rel_entity)  = pop @{[split '::', $related_class ]}; # Tag

    my $this_entity_plural = ucfirst Lingua::EN::Inflect::PL(lc $this_entity); # Videos
    my $rel_entity_plural  = ucfirst Lingua::EN::Inflect::PL(lc $rel_entity); # Tags

    my $link_relationship  = lc( $this_entity . '_' . $rel_entity_plural );  # video_tags
    my $link_class         = $namespace . $this_entity . $rel_entity; # MyApp::Schema::Result::VideoTag

    my $out_rel_name = lc $rel_entity_plural; # tags
    my $in_rel_name  = lc $this_entity_plural; # videos

    my $link_incoming_col = lc $this_entity . '_id'; # video_id
    my $link_outgoing_col = lc $rel_entity . '_id'; # tag_id

    # load classes
    Class::Load::load_class($related_class);
    Class::Load::load_class($link_class);

    # setup link table
    $link_class->belongs_to( lc($this_entity), $class, $link_incoming_col ); # belongs_to( 'video', 'MyApp::Schema::Result::Video', 'video_id'  )
    $link_class->belongs_to( lc($rel_entity), $related_class, $link_outgoing_col ); # belongs_to( 'tag', 'MyApp::Schema::Result::Tag', 'tag_id'  )

    # setup related classs
    $related_class->has_many($link_relationship, $link_class, $link_outgoing_col);
    $related_class->many_to_many($in_rel_name, $link_relationship, lc($this_entity));

    # setup this class
    $class->has_many($link_relationship, $link_class, $link_incoming_col); # has_many( 'video_tags', 'MyApp::Schema::Result::VideoTag', 'video_id' )
    $class->many_to_many($out_rel_name, $link_relationship, lc($rel_entity)); # many_to_many( 'tags', 'video_tags', 'tag' )

}







1;
