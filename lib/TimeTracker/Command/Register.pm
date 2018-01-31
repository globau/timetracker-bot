package TimeTracker::Command::Register;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use Moo;
use TimeTracker::Config ();
use TimeTracker::User   ();

extends 'TimeTracker::Command::Base';

sub _build_triggers {
    return [qw( register reg r )];
}

sub _build_help_short {
    return 'register for time tracking';
}

sub _build_help_long {
    my $channel = TimeTracker::Config->instance->irc_channel;
    return [
        'syntax: register',
        'register your current nick to be tracked by timetracker.',
        "you must be both registered and in $channel for your time to be tracked.",
    ];
}

sub execute {
    my ($self, $nick, $args) = @_;

    TimeTracker::User->register($nick);
    return ['you are now registered'];
}

1;
