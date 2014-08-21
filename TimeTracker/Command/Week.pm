package TimeTracker::Command::Week;
use Moo;
extends 'TimeTracker::Command::Base';

use DateTime::Format::Natural;
use DateTime;
use TimeTracker::Range;
use TimeTracker::User;

sub _build_triggers {[ qw( week w ) ]}

sub _build_help_short {
    'show a summary of your week',
}
sub _build_help_long {[
    'syntax: week [date]',
    'shows a summary of the hours online for the specified date.',
    'defaults to this week if no date is provided.',
]}

sub execute {
    my ($self, $nick, $args) = @_;
    my $user = TimeTracker::User->load($nick);
    my $today = $self->today($user);

    # parse args
    my $start_date = $self->parse_date($user, $args, 'week');

    # change to the previous monday (if not already a monday)
    $start_date->subtract(days => $start_date->day_of_week - 1);
    # and select the whole week
    my $end_date = $start_date->clone->add(days => 7)->add(minutes => -1);
    $end_date = $today->clone->add(days => 1)->add(minutes => -1)
        if $end_date > $today;

    my $range = TimeTracker::Range->new(
        start   => $start_date,
        end     => $end_date,
    );

    # grab active ranges
    my $ranges = $user->active($range);
    $ranges->split_into_days;

    # count days worked
    my %days;
    my $total_minutes = 0;
    my $date = $start_date->clone;
    while ($date <= $end_date) {
        $days{$date->ymd} = {
            date    => $date->clone,
            minutes => 0,
            edited  => 0,
        };
        $date->add(days => 1);
    }
    foreach my $range ($ranges->each) {
        $days{$range->start->ymd}{minutes} += $range->minutes;
        $total_minutes += $range->minutes;
    }

    # process edits
    foreach my $ymd (sort keys %days) {
        my $edits = TimeTracker::Edits->load($user, $days{$ymd}{date});
        foreach my $edit ($edits->each) {
            $days{$ymd}{minutes} += $edit->minutes;
            $days{$ymd}{edited} = 1;
            $total_minutes += $edit->minutes;
        }
    }

    # report
    my @response;
    my $hours_per_day = ($user->work_week * 60) / 5;
    push @response, $self->format_response(
        minutes => $total_minutes,
        caption => 'Week',
        target  => $user->work_week * 60,
        extra   => $user->work_week . '/week : ' . $range->format_cldr('d MMM'),
    );
    foreach my $ymd (sort keys %days) {
        # don't report on the weekend unless there were hours logged
        next if $days{$ymd}{date}->day_of_week > 5 && $days{$ymd}{minutes} == 0;

        push @response, $self->format_response(
            minutes => $days{$ymd}{minutes},
            caption => sprintf('%-9s', $days{$ymd}{date}->day_name),
            target  => $hours_per_day,
            extra   => ($days{$ymd}{edited} ? '*' : ''),
        );
    }
    return \@response;
}

1;
