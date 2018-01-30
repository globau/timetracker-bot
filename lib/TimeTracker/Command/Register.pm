package TimeTracker::Command::Register;
use Moo;
extends 'TimeTracker::Command::Base';

use TimeTracker::Config;
use TimeTracker::User;

sub _build_triggers {[ qw( register reg r ) ]}

sub _build_help_short {
    'register for time tracking'
}

sub _build_help_long {
    my $channel = TimeTracker::Config->instance->irc_channel;
    [
        'syntax: register',
        'register your current nick to be tracked by timetracker.',
        "you must be both registered and in $channel for your time to be tracked.",
    ]
}

sub execute {
    my ($self, $nick, $args) = @_;

    TimeTracker::User->register($nick);
    return [ 'you are now registered' ];
}

1;
