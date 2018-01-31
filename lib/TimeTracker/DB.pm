package TimeTracker::DB;
use strict;
use v5.10;
use warnings;

use DBI                 ();
use TimeTracker::Config ();

#
# singleton
#

my $_instance;

sub instance {
    my $class = shift;
    if (!defined($_instance)) {
        my $config = TimeTracker::Config->instance;
        $_instance = DBI->connect(
            sprintf('DBI:mysql:database=%s;host=%s;port=%s', $config->db_name, $config->db_host, $config->db_port),
            $config->db_user,
            $config->db_pass, {
                RaiseError           => 1,
                mysql_enable_utf8    => 1,
                mysql_auto_reconnect => 1,
            },
        );
    }
    return $_instance;
}

package DBI::db;  ## no critic (NamingConventions::Capitalization)
use strict;
use v5.10;
use warnings;

sub selectall_hash {
    my ($self, $sql, @args) = @_;
    return @{ $self->selectall_arrayref($sql, { Slice => {} }, @args) };
}

sub selectrow_hash {
    my ($self, $sql, @args) = @_;
    return ($self->selectall_hash($sql, @args))[0];
}

sub table_exists {
    my ($self, $table) = @_;
    return $self->selectrow_array(
        'SELECT 1 FROM information_schema.TABLES WHERE TABLE_NAME = ? AND TABLE_SCHEMA = ?',
        undef, $table, TimeTracker::Config->instance->db_name,
    );
}

sub add_table {
    my ($self, $table, $sql) = @_;
    return if $self->table_exists($table);
    say "creating table $table";
    $self->do($sql);
}

1;
