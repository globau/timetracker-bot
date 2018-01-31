package TimeTracker::Command::Ping;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use Moo;
use TimeTracker::Commands;

extends 'TimeTracker::Command::Base';

sub _build_triggers {
    return [qw( ping )];
}

sub _build_help_short {
    return 'responds with "pong"';
}

sub _build_help_long {
    return ['syntax: ping', 'responds with "pong".  used to test the responsiveness of the bot.',];
}

sub execute {
    my ($self, $nick, $args) = @_;
    return ['pong'];
}

1;
