package TimeTracker::DB;
use Moo;

use DBI;
use TimeTracker::Config;

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
            $config->db_user, $config->db_pass,
            {
                RaiseError              => 1,
                mysql_enable_utf8       => 1,
                mysql_auto_reconnect    => 1,
            },
        );
    }
    return $_instance;
}

package DBI::db;

use strict;
use warnings FATAL => "all";

sub selectall_hash {
    my ($self, $sql, @args) = @_;
    return @{ $self->selectall_arrayref($sql, { Slice => {} }, @args) };
}

sub selectrow_hash {
    my ($self, $sql, @args) = @_;
    return ($self->selectall_hash($sql, @args))[0];
}

sub table_exists {
    my $self = shift;
    my ($table) = @_;

    return $self->selectrow_array("
        SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_NAME = ?
                AND TABLE_SCHEMA = ?
        ",
        undef,
        $table,
        TimeTracker::Config->instance->db_name,
    );
}

sub add_table {
    my $self = shift;
    my ($table, $sql) = @_;
    return if $self->table_exists($table);
    print "creating table $table\n";
    $self->do($sql);
}

1;

