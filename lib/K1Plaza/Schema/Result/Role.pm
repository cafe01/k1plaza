package K1Plaza::Schema::Result::Role;

use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ Core /];


primary_column 'id' => {
   data_type => 'int',
   is_auto_increment => 1,
};

column rolename => {
    data_type     => 'varchar',
    size          => 192
};


sub as_hashref {
    +{ shift->get_columns }
}

sub TO_JSON {
    shift->as_hashref
}



1;



__END__

=pod

=head1 NAME

K1Plaza::Schema::Result::Role

=cut
