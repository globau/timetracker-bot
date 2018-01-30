package TimeTracker::Command::Status;
use Moo;
extends 'TimeTracker::Command::Base';

use TimeTracker::User;

sub _build_triggers {[ qw( status st s ) ]}

sub _build_help_short {
    'displays your current away/online status'
}
sub _build_help_long {[
    'syntax: status',
    'displays the last known status of your nick, either Away or Online.',
]}

sub execute {
    my ($self, $nick, $args) = @_;

    my $status = TimeTracker::User->load($nick)->last_status;
    return [ $status eq 'A' ? 'Away' : 'Online' ];
}

1;
