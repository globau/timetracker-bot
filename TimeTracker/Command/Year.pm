package TimeTracker::Command::Year;
use Moo;
extends 'TimeTracker::Command::Base';

use DateTime::Format::Natural;
use DateTime;
use TimeTracker::Range;
use TimeTracker::User;

sub _build_triggers {[ qw( year y ) ]}

sub _build_help_short {
    'show a summary of the year',
}
sub _build_help_long {[
    'syntax: year [year]',
    'shows a summary of the months online for the specified calendar year.',
]}

sub execute {
    my ($self, $nick, $args) = @_;
    my $user = TimeTracker::User->load($nick);
    my $today = $self->today($user);

    # parse args
    my $start_date = $self->parse_date($user, $args, 'year');

    # expand to the whole year
    $start_date->set(month => 1, day => 1);
    my $end_date = $start_date->clone->add(years => 1)->add(minutes => -1);
    $end_date = $today if $end_date > $today;

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
            $total_minutes += $edit->minutes;
        }
    }

    # consolidate into months
    my %months;
    foreach my $ymd (sort keys %days) {
        my $date = $days{$ymd}{date};
        $months{$date->month} ||= {
            name    => $date->format_cldr('MMM'),
            minutes => 0,
        };
        $months{$date->month}{minutes} += $days{$ymd}{minutes};
    }

    # report
    my @response;
    my $total = 0;
    foreach my $month (sort { $a <=> $b } keys %months) {
        push @response, $self->format_response(
            minutes => $months{$month}{minutes},
            caption => $months{$month}{name},
            wide    => 1,
        );
        $total += $months{$month}{minutes};
    }
    push @response, $self->format_response(
        minutes => $total,
        caption => 'Total',
        wide    => 1,
    );
    return \@response;
}

1;
