package TimeTracker::Command::Day;
use Moo;
extends 'TimeTracker::Command::Base';

use DateTime::Format::Natural;
use DateTime;
use TimeTracker::Range;
use TimeTracker::User;
use TimeTracker::Util;

sub _build_triggers {[ qw( day d today ) ]}

sub _build_help_short {
    'show details for a day',
}
sub _build_help_long {[
    'syntax: day [date]',
    'shows details of the hours online for the specified date.',
    'defaults to today if no date is provied.',
]}

sub execute {
    my ($self, $nick, $args) = @_;
    my $user = TimeTracker::User->load($nick);
    my $today = $self->today($user);

    # parse args
    my $start_date = $self->parse_date($user, $args, 'day');
    my $end_date = $start_date->clone->add(days => 1)->add(minutes => -1);

    my $range = TimeTracker::Range->new(
        start   => $start_date,
        end     => $end_date,
    );

    # count total minutes worked
    my $ranges = $user->active($range);
    my $edits = TimeTracker::Edits->load($user, $start_date);
    my $total = 0;
    foreach my $range ($ranges->each) {
        $total += $range->minutes;
    }
    foreach my $edit ($edits->each) {
        $total += $edit->minutes;
    }

    my @response;
    push @response, $range->format_cldr('d MMM') . '  ' . format_minutes($total);

    # active ranges
    foreach my $range ($ranges->each) {
        my $start_time = $range->start->format_cldr('hh:mm');
        my $end_time   = $range->end->format_cldr('hh:mm');
        push @response, $self->format_response(
            minutes => $range->minutes,
            extra   => "$start_time - $end_time",
        );
    }

    # edits
    foreach my $edit ($edits->each) {
        push @response, $self->format_response(
            minutes => $edit->minutes,
            extra   => $edit->reason,
            signed  => 1,
        );
    }

    return \@response;
}

1;
