package K1Plaza::Schema;

use Moo;
use namespace::autoclean;
extends 'DBIx::Class::Schema';
use Try::Tiny;
use Carp;
use Data::Printer;
use Mojo::IOLoop;
use feature qw(current_sub);


sub safe_deploy {
    my ($self, $log) = @_;
    my $storage = $self->storage;

    # all good
    return $self->_safe_deploy if eval { $storage->ensure_connected; 1 };

    # wait for database connection
    $log->debug("Waiting for database connection...") if $log;
    Mojo::IOLoop->timer(1, sub {
        my $loop = shift;

        my $connected = eval { $storage->ensure_connected; 1 };
        if ($connected) {
            $log->debug("Database connection established, running safe-deploy.");
            $self->_safe_deploy;
            return;
        }

        $loop->timer(1, __SUB__);
    });
}


sub _safe_deploy {
    my $self       = shift;
    my $statements = $self->deployment_statements(undef, undef, undef, { no_comments => 1 });
    $statements =~ s/CREATE TABLE/CREATE TABLE IF NOT EXISTS/g;
    $statements =~ s/(?<!;)\n//g;
    my @statements = split "\n", $statements;

    my $storage = $self->storage;
    my $deploy = sub {
        my $line = shift;
        return if ( !$line );
        return if ( $line =~ /^--/ );

        # next if($line =~ /^DROP/m);
        return if ( $line =~ /^BEGIN TRANSACTION/m );
        return if ( $line =~ /^COMMIT/m );
        return if $line =~ /^\s+$/;                     # skip whitespace only
        $storage->_query_start($line);
        try {
            # do a dbh_do cycle here, as we need some error checking in
            # place (even though we will ignore errors)
            $storage->dbh_do( sub { $_[1]->do($line) } );
        }
        catch {
            carp qq{$_ (running "${line}")};
        };
        $storage->_query_end($line);
    };

    foreach my $statement (@statements) {
        $deploy->($statement);
    }

    # create system tenant
    $self->resultset('AppInstance')
         ->find_or_create({ id => -1, name => 'SYSTEM', canonical_alias => 'SYSTEM' });

}

__PACKAGE__->load_namespaces;

1;
