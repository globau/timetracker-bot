package TimeTracker::Command::Day;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use Moo;
use TimeTracker::Range ();
use TimeTracker::User  ();

extends 'TimeTracker::Command::Base';

sub _build_triggers {
    return [qw( day d today )];
}

sub _build_help_short {
    return 'show details for a day';
}

sub _build_help_long {
    return [
        'syntax: day [date]',
        'shows details of the hours online for the specified date.',
        'defaults to today if no date is provided.',
    ];
}

sub execute {
    my ($self, $nick, $args) = @_;
    my $user  = TimeTracker::User->load($nick);
    my $today = $self->today($user);

    # parse args
    my $start_date = $self->parse_date($user, $args, 'day');
    my $end_date = $start_date->clone->add(days => 1)->add(minutes => -1);

    my $range = TimeTracker::Range->new(
        start => $start_date,
        end   => $end_date,
    );

    # count total minutes worked
    my $ranges = $user->active($range);
    my $edits  = TimeTracker::Edits->load($user, $start_date);
    my $total  = 0;
    foreach my $range ($ranges->iter) {
        $total += $range->minutes;
    }
    foreach my $edit ($edits->iter) {
        $total += $edit->minutes;
    }

    my @response;
    push @response,
        $self->format_response(
        minutes   => $total,
        caption   => $range->format_cldr('d MMM'),
        target    => ($user->work_week * 60) / 5,
        delimiter => ':',
        );

    # active ranges
    foreach my $range ($ranges->iter) {
        my $start_time = $range->start->format_cldr('HH:mm');
        my $end_time   = $range->end->format_cldr('HH:mm');
        push @response,
            $self->format_response(
            minutes => $range->minutes,
            extra   => "$start_time - $end_time",
            );
    }

    # edits
    foreach my $edit ($edits->iter) {
        push @response,
            $self->format_response(
            minutes => $edit->minutes,
            extra   => $edit->reason,
            signed  => 1,
            );
    }

    return \@response;
}

1;
