package TimeTracker::Range;
use Moo;

use TimeTracker::Util;

use overload
    '""' => \&_as_string;

has start   => ( is => 'rw', required => 1, trigger => 1, coerce => \&_coerce_date);
has end     => ( is => 'rw', required => 1, trigger => 1, coerce => \&_coerce_date);
has minutes => ( is => 'rw', lazy => 1 );

sub _coerce_date {
    my ($date) = @_;
    $date->truncate(to => 'minute');
}

sub _trigger_start {
    my ($self, $value) = @_;
    $self->minutes($self->_build_minutes)
        if $self->start && $self->end;
}

sub _trigger_end {
    my ($self, $value) = @_;
    $self->minutes($self->_build_minutes)
        if $self->start && $self->end;
}

sub _build_minutes {
    my ($self) = @_;
    return $self->start->between($self->end, 'minutes');
}

sub clone {
    my ($self) = @_;
    return TimeTracker::Range->new(
        start   => $self->start->clone,
        end     => $self->end->clone,
    );
}

sub _as_string {
    my ($self) = @_;
    return sprintf(
        "%s - %s [%s] (%s)",
        $self->start->format_cldr('yyyy-MM-dd HH:mm'),
        $self->end->format_cldr('yyyy-MM-dd HH:mm'),
        $self->start->time_zone->name,
        $self->minutes,
    );
}

sub set_time_zone {
    my ($self, $time_zone) = @_;
    $self->start->set_time_zone($time_zone);
    $self->end->set_time_zone($time_zone);
}

sub format_cldr {
    my ($self, $format) = @_;
    my ($start, $end) = ($self->start, $self->end);
    return ''
        unless $start;
    return $start->format_cldr($format)
        unless $end;
    return $start->format_cldr($format) . ' - ' . $end->format_cldr($format);
}

1;
