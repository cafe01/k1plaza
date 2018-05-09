package K1Plaza::Schema::Result::UserRole;

use DBIx::Class::Candy -autotable => v1,
                       -components => [qw/ Core/];


column 'user_id' => {
   data_type => 'int',   
};

column 'role_id' => {
   data_type => 'int',   
};

primary_key 'user_id', 'role_id';

1;



__END__

=pod

=head1 NAME 

K1Plaza::Schema::Result::UserRole

=cut