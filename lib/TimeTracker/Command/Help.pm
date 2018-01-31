package TimeTracker::Command::Help;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use Moo;
use TimeTracker::Commands;

extends 'TimeTracker::Command::Base';

sub _build_triggers {
    return [qw( help h ? )];
}

sub _build_help_short {
    return 'shows command help';
}

sub _build_help_long {
    return ['syntax: help [command]', 'displays a list of commands, or help for a specific command if provided.',];
}

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
        return ['@private', @{ $handler->help_long }]; ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    } else {
        return ["unknown command '$args'"];
    }
}

1;
