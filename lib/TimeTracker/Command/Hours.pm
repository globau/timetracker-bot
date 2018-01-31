package TimeTracker::Command::Hours;
##  no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use Moo;
use TimeTracker::User ();

extends 'TimeTracker::Command::Base';

sub _build_triggers {
    return [qw( hours work )];
}

sub _build_help_short {
    return 'displays/sets the number of hours you work per week';
}

sub _build_help_long {
    return [
        'syntax: hours [hours]',
        'displays or sets the number of hours you work per week.',
        'the default is 40 hours per week.',
    ];
}

sub execute {
    my ($self, $nick, $args) = @_;

    my $user = TimeTracker::User->load($nick);

    if (!$args) {
        return [$user->work_week . ' hours/week'];
    } else {
        die "invalid value for hours per week\n"
            if $args !~ /^\d+(?:.\d+)?$/ || $args <= 0;
        $user->work_week($args);
        $user->commit();
        return ["hours/week updated to $args"];
    }
}

1;
