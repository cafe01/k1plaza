package Q1::Web::Widget::GoogleMap;

use utf8;
use Q1::Moose::Widget;
use namespace::autoclean;
use Q1::jQuery;

extends 'Q1::Web::Widget';


has '+is_ephemeral', default => 1;

has 'api_key', is => 'ro', isa => 'Str', default => 'AIzaSyAvrHfE9DmYmqKMjeGnp_Y5stBp7xmg-fc';


has_param 'id',  isa => 'Str', default => sub{ int(rand 999) };
has_param 'lat',  isa => 'Str', default => '-34.397';
has_param 'lng',  isa => 'Str', default => '150.644';
has_param 'zoom', isa => 'Int', default => 8;
has_param 'maptype', isa => 'Str', default => 'ROADMAP';
has_param 'width', isa => 'Str', default => '400';
has_param 'height', isa => 'Str', default => '400';




=pod

function loadScript() {
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.src = "http://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&sensor=TRUE_OR_FALSE&callback=initialize";
  document.body.appendChild(script);
}

=cut

sub render_snippet {
    my ($self, $el, $params, $engine) = @_;
    my $tx = $self->tx;
    my $api_key = $self->api_key;

    # element id
    my $element_id = $el->attr('id') || 'map'.int(rand 999);
    $el->attr('id', $element_id);

    # is xtag? add a div to be rendered as map by client-side maps library
    if ($el->tagname =~ /^x-/) {
        my $w = $self->width;
        my $h = $self->height;

        $w .= 'px' if $w =~ /^\d+$/;
        $h .= 'px' if $h =~ /^\d+$/;

        $el->html(sprintf '<div id="%s" style="width:%s; height: %s;" />', $element_id, $w, $h);
    }

    # map js var
    my $map_var = $element_id;
    $map_var =~ tr/-/_/;

    # build javascript initialization code
    my $init_func_name = 'init'. ucfirst $map_var;
    my $load_func_name = 'load'. ucfirst $map_var;

    my $js_map_init = sprintf 'window.%s = function() { %s = new google.maps.Map(document.getElementById("%s"), { zoom: %d, center: new google.maps.LatLng(%s, %s), mapTypeId: google.maps.MapTypeId.%s }); new google.maps.Marker({ map: %s, position: new google.maps.LatLng(%s, %s) }) }',
       $init_func_name, $map_var, $el->attr('id'), $self->zoom, $self->lat, $self->lng, uc $self->maptype, $map_var, $self->lat, $self->lng;

    my $js_code = <<CODE;

$js_map_init;

(function () {
  //if (!arguments.callee.caller) return;
  function log() {
      if (!console || typeof console.log != "function") return;
      console.log.apply(console, arguments);
  }

  log('loading map $element_id', arguments.callee.caller);

  if ("google" in window && "maps" in google) {
      log('google maps api already loaded, calling $init_func_name()')
      $init_func_name();
      return;
  }

  if (window.loadingGoogleMaps) return;

  log('injecting maps api');
  window.loadingGoogleMaps = true;
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.src = "http://maps.googleapis.com/maps/api/js?key=$api_key&sensor=false&callback=$init_func_name";
  document.body.appendChild(script);
})();

CODE

    # push code to be rendered
    #push @{$engine->context->{append_javascript}}, $js_code;
    my $script = j('<script type="text/javascript" />');
    $script->text($js_code);
    $script->insert_after($el);
}














__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=head1 NAME

Q1::Web::Widget::GoogleMap

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
