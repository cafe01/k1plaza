package K1Plaza::Sitemap;

use Mojo::Base 'Mojolicious::Routes';
use Carp qw/confess/;
use feature qw(current_sub);
use Data::Printer;


sub path_for {
    my $self = shift;
    my $route_name = shift;
    my $route = $self->find($route_name)
        or confess "Can't find route '$route_name'";

    $route->render(ref $_[0] ? $_[0] : { @_ });
}


sub from_source {
    my ($class, $source, $c) = @_;
    die "from_source() must be called as a Class method" if ref $class;

    my $root_page;

    my $process_page = sub {
        my ($page, $routes, $current_path, $route_prefix, $route_contraints, $route_defaults) = @_;

        # shallow copy
        $route_defaults //= {};
        $page = {%$page};

        # fullpath
        my $page_path = delete $page->{path};
        $page->{fullpath} = $current_path ? "$current_path/$page_path" : $page_path;
        my $name_suffix = $page->{fullpath} =~ s/\/:?/-/gr;

        # detect root page
        $root_page = $page if ($source->{root}||'') eq $page->{fullpath} || $page->{is_root};

        # remove children to avoid pollution of created routes
        my $children = delete $page->{page};

        # simple route (no children expected)
        my $route_path = join '/', $route_prefix||'', $page_path, $page->{args} || ();
        # $route_path .= "/$page->{args}"


        unless ($children || $page->{widget_args}) {
            $routes->get($route_path, $route_contraints||())->to({ %$route_defaults, %$page})->name("page-$name_suffix");
            return;
        }

        # create "under" for child routes
        my $route = $routes->under($route_path, $route_contraints||())
                           ->name($page->{path_only} ? "path-$name_suffix" : "page-$name_suffix")
                           ->to({ %$route_defaults, %$page});

        # under-root endpoint
        $route->get("/")->to($page)->name("page-$name_suffix-root")
            unless $page->{path_only};

        # widget args
        my $widget;
        if ($c && $page->{widget_args} && ($widget = $c->widget($page->{widget_args})) && $widget->can('routes')) {

            foreach my $widget_route (@{$widget->routes}) {
                my $inner = $route->get(@$widget_route);
                my $inner_name = $inner->pattern->unparsed =~ s/\W+/-/gr;
                $inner_name =~ s/^-//;
                $inner->name(join '-', 'widget', $widget->name, $inner_name);
            }
        }

        # child pages
        if ($children) {
            __SUB__->($_, $route, $page->{fullpath}) for @$children;
        }
    };


    my $sitemap = $class->new;

    my ($route_prefix, $route_defaults);
    my $route_contraints = [format => 0];

    my $locales = $source->{locales};
    $locales = $c->app_instance->config->{locales}
        if $c && $c->has_app_instance && $c->app_instance->config->{locales};

    if ($locales) {

        $locales = [$locales] unless ref $locales;
        my $default_locale =  $locales->[0];
        $route_prefix     = '/:locale';
        $route_defaults   = { locale => $default_locale };
        push @$route_contraints, locale => $locales;
    }

    foreach my $page (@{$source->{page}}) {
        $process_page->($page, $sitemap, '', $route_prefix, $route_contraints, $route_defaults);
    }

    my $root_path = $route_prefix ? $route_prefix.'/' : '/';
    $sitemap->get($root_path, $route_contraints||())
            ->to({ %{$route_defaults||{}}, %$root_page})
            ->name('website-root') if $root_page;

    $sitemap;
}


sub from_dir {
    my ($class, $root_dir, $c) = @_;
    die "missing second arg 'c'" unless $c;
    my $plift = $c->plift;

    my $root_page;

    my $process = sub {
        my ($routes, $files) = @_;

        my @sorted = sort {
            -d $a cmp -d $b
                ||
            $a cmp $b
        } $files->each;

        foreach my $file (@sorted) {

            my $basename = $file->basename;

            # dir
            if (-d $file) {
                my $fullpath = $file->to_rel($root_dir)->to_string;

                my $name_suffix = $fullpath =~ s/\//-/rg;
                my $under;
                if ($under = $routes->find("page-$name_suffix")) {

                    # add root endpoint
                    $under->get("/")->name("page-$name_suffix-root")

                }
                else {
                    $under = $routes->under($basename)
                                    ->to({ title => $basename })
                                    ->name("path-$name_suffix");
                }

                __SUB__->($under, $file->list({ dir => 1 }));
            }

            # valid template formats: html and md
            my $valid_formats = qr/\.(?:html|md)$/;
            next unless $basename =~ $valid_formats;
            $basename =~ s/$valid_formats//;

            # ignore alternative templates
            next if $basename =~ /\./;

            # fullpath
            my $fullpath = $file->to_rel($root_dir)->to_string;
            $fullpath =~ s/$valid_formats//;

            # extract other sitemap page options from <x-meta> elements
            local $plift->{metadata} = {};
            local $plift->{context} = {};
            local $plift->{include_path} = [$root_dir];
            my $page_dom = $plift->load_template($fullpath);
            my $page = $plift->metadata;

            # default title
            $page->{title} //= $basename;

            # root page
            $root_page = $page if $page->{is_root};

            # simple route (no children expected)
            $page->{fullpath} = $fullpath;
            my $name_suffix = $fullpath =~ s/\/:?/-/gr;
            my $route_path = join '/', $basename, $page->{args} || ();
            
            unless ($page->{widget_args}) {
                $routes->get($route_path)->to($page)->name("page-$name_suffix");
                next;
            }

            # create "under" for child routes
            my $route = $routes->under($route_path)
                               ->name("page-$name_suffix")
                               ->to($page);
                            
            $route->get("/")->name("page-$name_suffix-root");

            # widget args
            my $widget;
            if ($c->has_app_instance && ($widget = $c->widget($page->{widget_args})) && $widget->can('routes')) {

                foreach my $widget_route (@{$widget->routes}) {
                    my $inner = $route->get(@$widget_route);
                    my $inner_name = $inner->pattern->unparsed =~ s/\W+/-/gr;
                    $inner_name =~ s/^-//;
                    $inner->name(join '-', 'widget', $widget->name, $inner_name);
                }
            }

        }
    };


    my $sitemap = $class->new;
    $process->($sitemap, $root_dir->list({ dir => 1 }));

    # root page
    unless ($root_page) {
        my $index = $sitemap->find('page-index');
        $root_page = $index->to if $index;
    }

    $sitemap->get('/')->to($root_page)->name('website-root')
        if $root_page;


    $sitemap;
}



sub page_tree {
    my ($self, $root_route) = @_;
    my @tree;
    my $stack = [\@tree];
    my $current_depth = 0;
    my $last_node;

    $root_route //= '.';

    $self->walk($root_route, sub {
        my ($node, $route, $depth) = @_;

        if ($depth > $current_depth) {

            $last_node->{children} = [];
            push @$stack, $last_node->{children};
        }
        elsif ($depth < $current_depth) {
            my $steps = $current_depth - $depth;
            pop @$stack for (1 .. $steps);
        }

        push @{$stack->[-1]}, $node;
        $last_node = $node;
        $current_depth = $depth;
    });

    \@tree;
}


sub walk {
    my ($self, $root_route, $cb) = @_;

    confess "using old signature" if ref $root_route;

    my $walk = sub {
        my ($routes, $depth) = @_;
        my @items;
        foreach my $route (@$routes) {

            my %item = %{$route->pattern->defaults};
            next if $route->name !~ /^(page|path)-/;
            $item{route} = $route->name;

            # skip page-*-root as it would appear as duplicate and child of actual node
            next if $route->name =~ /^page-.*-root$/;

            # process
            $cb->(\%item, $route, $depth);

            my @children = @{$route->children};
            if(@children) {

                # a "/" children is the actual current item we want
                # if (($children[0]->pattern->unparsed || '/') eq '/') {
                #     %item = %{shift(@children)->pattern->defaults};
                # }

                # sub items
                __SUB__->(\@children, $depth + 1);
            }
        }
    };

    my $nodes = $root_route eq '.' 
        ? $self->children
        : $self->find($root_route)->children;

    $walk->($nodes, 0);
}




1;
