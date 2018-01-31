package TimeTracker::Util;
use strict;
use v5.10;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = qw(
    canon_nick
    format_minutes
);

sub canon_nick {
    my $nick = lc(shift);
    $nick =~ s/(^\s+|\s+$)//g;
    $nick =~ s/^([^|_-]+)[|_-].+/$1/;
    return $nick;
}

sub format_minutes {
    my ($minutes, $always_show_sign, $hour_width) = @_;
    $hour_width ||= 2;
    my $sign = $minutes < 0 ? '-' : ($always_show_sign ? '+' : '');
    $minutes = abs($minutes);
    my $hours = int($minutes / 60);
    $minutes = $minutes % 60;
    return sprintf("$sign%0${hour_width}d:%02d", $hours, $minutes);
}

1;

package DateTime;
use strict;
use v5.10;
use warnings;

sub as_sql {
    my ($self) = @_;
    return $self->ymd('-') . ' ' . $self->hms(':');
}

sub from_sql {
    my ($class, $value) = @_;
    my ($yyyy, $mm, $dd, $hh, $nn, $ss) = $value =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/;
    return $class->new(
        year      => $yyyy,
        month     => $mm,
        day       => $dd,
        hour      => $hh,
        minute    => $nn,
        second    => $ss,
        time_zone => 'UTC',
    );
}

sub between {
    my ($self, $other, $units) = @_;
    return $self->delta_ms($other)->in_units($units);
}

1;
