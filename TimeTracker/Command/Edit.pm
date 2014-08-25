package TimeTracker::Command::Edit;
use Moo;
extends 'TimeTracker::Command::Base';

use Scalar::Util qw(blessed);
use Text::ParseWords;
use TimeTracker::Edit;
use TimeTracker::Edits;
use TimeTracker::User;
use TimeTracker::Util;

sub _build_triggers {[ qw( edit ed e ) ]}

sub _build_help_short {
    'adjust hours worked'
}
sub _build_help_long {[
    'syntax: edit "date" "adjustment" "reason"',
    'adjusts the hours worked for the specified date.',
    'eg. edit "last tuesday" "+8 hours" "public holidays"',
    'eg. edit 2014-04-29 -45m left myself logged in during lunch',
]}

sub execute {
    my ($self, $nick, $args) = @_;
    my $user = TimeTracker::User->load($nick);

    # split into date/adjustment/reason
    my @args = quotewords('\s+', 0, $args);
    die $self->help_long->[0] . "\n"
        unless scalar(@args) >= 3;
    my ($date, $adjustment) = (shift @args, shift @args);
    my $reason = join(' ', @args);

    # parse date
    $date = $self->parse_date($user, $date);
    $date->truncate(to => 'day');

    # parse adjustment
    die "invalid adjustment '$adjustment'\n"
        unless $adjustment =~ /^([+-]?\d+(?:\.\d+)?)\s*(m|minutes?|h|hours?|d|days?)$/i;
    my ($adjust_amount, $adjust_scale) = ($1, $2);
    $adjust_scale = lc(substr($adjust_scale, 0, 1));
    if ($adjust_scale eq 'd') {
        $adjustment = 60 * ($user->work_week / 5);
    } elsif ($adjust_scale eq 'h') {
        $adjustment = 60 * $adjust_amount;
    } else {
        $adjustment = $adjust_amount;
    }

    # validate adjustment
    die "adjustment is too large\n"
        if abs($adjustment) > 60 * 24;

    # grab active ranges
    my $active_minutes = 0;
    if ($nick eq 'glob') {
        my $range = TimeTracker::Range->new(
            start   => $date,
            end     => $date->clone->add(days => 1)->add(minutes => -1),
        );
        my $ranges = $user->active($range);
        $ranges->split_into_days;
        foreach my $range ($ranges->each) {
            $active_minutes += $range->minutes;
        }
    }

    my $edits = TimeTracker::Edits->load($user, $date);
    $active_minutes += $edits->minutes;
    die "total adjustments for " . $date->format_cldr('d MMMM') . " would exceed 24 hours\n"
        if $active_minutes + $adjustment > 60 * 24;
    die "total adjustments for " . $date->format_cldr('d MMMM') . " would be less than zero hours\n"
        if $active_minutes + $adjustment < 0;

    my $edit = TimeTracker::Edit->new(
        nick    => $user->nick,
        date    => $date,
        minutes => $adjustment,
        reason  => $reason,
    );
    $edit->commit();
    return [ "updated $edit" ];
}

1;
