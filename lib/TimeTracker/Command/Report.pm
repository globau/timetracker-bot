package TimeTracker::Command::Report;
use Moo;
extends 'TimeTracker::Command::Base';

use DateTime::Format::Natural;
use DateTime;
use TimeTracker::Range;
use TimeTracker::User;

sub _build_triggers {[ qw( report r ) ]}

sub _build_help_short {
    'show a per-month summary of the specified range',
}
sub _build_help_long {[
    'syntax: report [start month] [end month]',
    'shows a summary of the months online for the specified range.',
    'shows the current calendar year if no start month provided.',
]}

sub execute {
    my ($self, $nick, $args) = @_;
    my $user = TimeTracker::User->load($nick);
    my $today = $self->today($user);

    # parse args
    my ($start_arg, $end_arg) = split(/\s+/, $args // '');
    my $start_date;
    if ($start_arg) {
        $start_arg .= '-01' if $start_arg && $start_arg =~ /^\d\d\d\d-\d\d$/;
        $start_date = $self->parse_date($user, $start_arg, 'month');
    } else {
        $start_date = $today->clone->set(month => 1, day => 1);
    }
    $start_date->set(day => 1)->truncate(to => 'month');

    my $end_date;
    if ($end_arg) {
        $end_arg .= '-01' if $end_arg =~ /^\d\d\d\d-\d\d$/;
        $end_date = $self->parse_date($user, $end_arg, 'month');
        $end_date->add(months => 1)->add(minutes => -1);
    } else {
        $end_date = $start_date->clone->add(years => 1)->add(minutes => -1);
    }
    $end_date = $today if $end_date > $today;
    $start_date->truncate(to => 'month');

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

    # consolidate into months;
    my %months;
    foreach my $ymd (keys %days) {
        my $date = $days{$ymd}{date};
        my $ym = $date->format_cldr('yyyyMM');
        $months{$ym} ||= {
            name    => $date->format_cldr('yyyy MMM'),
            minutes => 0,
        };
        $months{$ym}{minutes} += $days{$ymd}{minutes};
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
