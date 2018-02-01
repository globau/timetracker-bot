package TimeTracker::Command::Status;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use Moo;
use TimeTracker::User ();

extends 'TimeTracker::Command::Base';

sub _build_triggers {
    return [qw( status st s )];
}

sub _build_help_short {
    return 'displays your current away/online status';
}

sub _build_help_long {
    return ['syntax: status', 'displays the last known status of your nick, either Away or Online.',];
}

sub execute {
    my ($self, $nick, $args) = @_;

    my $status = TimeTracker::User->load($nick)->last_status;
    return [$status eq 'A' ? 'Away' : 'Online'];
}

1;
