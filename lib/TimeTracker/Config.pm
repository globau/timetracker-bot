package TimeTracker::Config;
use Moo;

use File::Slurp;
use FindBin qw($RealBin);
use Mojo::JSON qw(decode_json);

#
# propertie qw(decode_json);
#

has db_host => ( is => 'ro' );
has db_port => ( is => 'ro' );
has db_name => ( is => 'ro' );
has db_user => ( is => 'ro' );
has db_pass => ( is => 'ro' );

has irc_host        => ( is => 'ro' );
has irc_port        => ( is => 'ro' );
has irc_channel     => ( is => 'ro' );
has irc_nick        => ( is => 'ro' );
has irc_password    => ( is => 'ro' );
has irc_name        => ( is => 'ro' );

has pid_file        => ( is => 'lazy' );
has log_file        => ( is => 'lazy' );
has command_file    => ( is => 'lazy' );
has debug           => ( is => 'rw', default => sub { 0 } );

around BUILDARGS => sub {
    my ($orig, $class) = @_;
    my $config = decode_json(scalar read_file("$RealBin/configuration.json"));

    $config->{db_port} ||= 3306;
    $config->{irc_port} ||= 6668;
    $config->{irc_name} ||= $config->{irc_nick};

    return $class->$orig($config);
};

sub BUILD {
    my ($self) = @_;
    die "config requires db_host, db_name, db_user\n"
        unless $self->db_host && $self->db_name && $self->db_user;
    die "config requires irc_host, irc_channel, irc_nick\n"
        unless $self->irc_host && $self->irc_channel && $self->irc_nick;
}

sub _build_pid_file { "$RealBin/timetracker.pid" }
sub _build_log_file { "$RealBin/timetracker.log" }
sub _build_command_file { "$RealBin/command" }

#
# singleton
#

my $_instance;
sub instance {
    my $class = shift;
    return defined $_instance ? $_instance : ($_instance = $class->new(@_));
}

1;
