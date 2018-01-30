package TimeTracker::Command::Ping;
use Moo;
extends 'TimeTracker::Command::Base';

use TimeTracker::Commands;

sub _build_triggers {[ qw( ping ) ]}

sub _build_help_short {
    'responds with "pong"'
}
sub _build_help_long {[
    'syntax: ping',
    'responds with "pong".  used to test the responsiveness of the bot.',
]}

sub execute {
    my ($self, $nick, $args) = @_;
    return [ 'pong' ];
}

1;
