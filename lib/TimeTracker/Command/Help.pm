package TimeTracker::Command::Help;
use Moo;
extends 'TimeTracker::Command::Base';

use TimeTracker::Commands;

sub _build_triggers {[ qw( help h ? ) ]}

sub _build_help_short {
    'shows command help'
}
sub _build_help_long {[
    'syntax: help [command]',
    'displays a list of commands, or help for a specific command if provided.',
]}

sub execute {
    my ($self, $nick, $args) = @_;
    my $commands = TimeTracker::Commands->instance;

    if (!$args) {
        my @response = ('commands:');
        foreach my $handler (@{ $commands->handlers }) {
            next if $handler->help_short eq 'not implemented';
            push @response, $handler->triggers->[0] . ' - ' . $handler->help_short;
        }
        return \@response;
    } elsif (my $handler = $commands->handler_for($args)) {
        return [
            '@private',
            @{ $handler->help_long },
        ]
    } else {
        return [ "unknown command '$args'" ];
    }
}

1;
