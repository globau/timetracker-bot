package TimeTracker::Command::TimeZone;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use DateTime::TimeZone;
use Moo;
use TimeTracker::User;

extends 'TimeTracker::Command::Base';

sub _build_triggers {
    return [qw( timezone time_zone tz )];
}

sub _build_help_short {
    return 'displays/sets your time zone';
}

sub _build_help_long {
    return [
        'syntax: timezone [zone|find zone]',
        'displays or sets your time zone.',
        'use "find" to grep for valid time zones',
        'the default time zone is PST8PDT.',
    ];
}

sub execute {
    my ($self, $nick, $args) = @_;

    my $user = TimeTracker::User->load($nick);

    if (!$args) {
        return [$user->time_zone];

    } elsif ($args =~ s/^(?:find|grep)\s+(\S+)/$1/i) {
        my @response = grep {/$args/i} DateTime::TimeZone->all_names;
        unshift @response, '@private'  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
            if scalar(@response) > 5;
        return \@response;

    } else {
        my $query = $args;
        $query =~ s/ /_/g;
        if (my @found = grep {/$query/i} DateTime::TimeZone->all_names) {
            if (scalar(@found) == 1) {
                $args = $found[0];
            }
        }
        die "invalid time zone '$args'\n"
            unless DateTime::TimeZone->is_valid_name($args);
        $user->time_zone($args);
        $user->commit();
        return ["time zone updated to $args"];
    }
}

1;
