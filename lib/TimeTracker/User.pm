package TimeTracker::User;
use strict;
use v5.10;
use warnings;

use Moo;
use Readonly;
use TimeTracker::DB     ();
use TimeTracker::Edits  ();
use TimeTracker::Ranges ();
use TimeTracker::Util qw( canon_nick );

Readonly::Scalar my $DEFAULT_TIME_ZONE => 'PST8PDT';
Readonly::Scalar my $DEFAULT_WORK_WEEK => '40';

has nick => (is => 'ro', required => 1, coerce => sub { canon_nick($_[0]) });
has time_zone   => (is => 'rw');
has work_week   => (is => 'rw');
has last_status => (is => 'rw');

sub BUILD {
    my ($self) = @_;

    my $values = __PACKAGE__->_load_from_db($self->nick);
    die 'failed to load data for: ' . $self->nick . "\n"
        unless $values;

    # set properties
    $self->time_zone($values->{time_zone});
    $self->work_week($values->{work_week});
    $self->last_status($values->{last_status});
}

sub load {
    my ($class, $nick) = @_;
    die "'$nick' is not a registered nick\n"
        unless $class->registered($nick);
    return $class->new(nick => $nick);
}

sub _load_from_db {
    my ($class, $nick) = @_;
    my $dbh = TimeTracker::DB->instance;

    return $dbh->selectrow_hash('SELECT * FROM user WHERE nick=?', $nick);
}

sub register {
    my ($class, $nick) = @_;
    my $dbh = TimeTracker::DB->instance;

    if ($class->registered($nick)) {
        die "'$nick' is already registered\n";
    }

    $dbh->do('INSERT INTO user(nick, time_zone, work_week, last_status) VALUES(?, ?, ?, ?)',
        undef, $nick, $DEFAULT_TIME_ZONE, $DEFAULT_WORK_WEEK, 'O',);
}

sub registered {
    my ($class, $nick) = @_;
    my $dbh = TimeTracker::DB->instance;
    return $dbh->selectrow_hash('SELECT 1 FROM user WHERE nick=?', canon_nick($nick));
}

sub commit {
    my ($self) = @_;

    # don't update the database unless required
    my $values = __PACKAGE__->_load_from_db($self->nick)
        or return;
    return
           if $values->{last_status} eq $self->last_status
        && $values->{time_zone} eq $self->time_zone
        && $values->{work_week} eq $self->work_week;

    my $dbh = TimeTracker::DB->instance;
    $dbh->do('UPDATE user SET time_zone=?, work_week=?, last_status=? WHERE nick=?',
        undef, $self->time_zone, $self->work_week, $self->last_status, $self->nick,);
}

sub log_active {
    my ($self, $datetime) = @_;
    my $dbh  = TimeTracker::DB->instance;
    my $nick = $self->nick;

    $datetime->truncate(to => 'minute');

    # look for an existing range (fuzz to a few minutes)
    my $end_a = $datetime->clone->add(minutes => -2);
    my $end_b = $datetime->clone->add(minutes => 1);
    my $existing =
        $dbh->selectrow_hash('SELECT * FROM active WHERE nick=? AND end_time BETWEEN ? AND ?', $nick, $end_a, $end_b,);

    if ($existing) {

        # update existing range
        $dbh->do(
            'UPDATE active SET end_time=? WHERE nick=? AND start_time=?',
            undef, $datetime->as_sql, $nick, $existing->{start_time},
        ) unless $existing->{end_time} eq $datetime->as_sql;

    } else {

        # start a new range
        $dbh->do('INSERT INTO active(nick, start_time, end_time) VALUES(?, ?, ?)',
            undef, $nick, $datetime->as_sql, $datetime->as_sql,);
    }
}

sub active {
    my ($self, $range) = @_;
    my $dbh  = TimeTracker::DB->instance;
    my $nick = $self->nick;

    # dates in the database are utc
    $range = $range->clone;
    $range->set_time_zone('UTC');

    my $start_time_sql = $dbh->quote($range->start->as_sql);
    my $end_time_sql   = $dbh->quote($range->end->as_sql);

    # look for ranges
    my @rows = $dbh->selectall_hash(
        "SELECT start_time AS start, end_time AS end
           FROM active
          WHERE nick = ?
                AND
                (   (
                        ($start_time_sql BETWEEN start_time AND end_time)
                        AND ($end_time_sql BETWEEN start_time AND end_time)
                    ) OR (
                        ($start_time_sql BETWEEN start_time AND end_time)
                        AND ($end_time_sql > end_time)
                    ) OR (
                        ($start_time_sql < start_time)
                        AND ($end_time_sql BETWEEN start_time AND end_time)
                    ) OR (
                        (start_time > $start_time_sql)
                        AND (end_time < $end_time_sql)
                    )
                )
          ORDER BY start_time",
        $self->nick,
    );

    my $ranges = TimeTracker::Ranges->new();
    foreach my $row (@rows) {

        # parse sql dates
        $row->{start} = DateTime->from_sql($row->{start});
        $row->{end}   = DateTime->from_sql($row->{end});

        # if the range is partial, truncate
        $row->{start} = $range->start
            if $row->{start} < $range->start;
        $row->{end} = $range->end
            if $row->{end} > $range->end;

        # and add to the ranges
        $ranges->add(%{$row});
    }

    # convert to the user's timezone
    $ranges->set_time_zone($self->time_zone);
    return $ranges;
}

sub edits {
    my ($self, $date) = @_;
    my $dbh  = TimeTracker::DB->instance;
    my $nick = $self->nick;

    # dates in the database are utc
    $date = $date->clone;
    $date->set_time_zone('UTC');

    # look for edits
    my @rows = $dbh->selectall_hash(
        'SELECT minutes, reason
           FROM edits
          WHERE nick = ? AND date = ?
          ORDER BY date',
        $self->nick, $date->as_sql,
    );

    my $edits = TimeTracker::Edits->new();
    foreach my $row (@rows) {
        $row->{date} = $date;
        $edits->add(%{$row});
    }
    return $edits;
}

1;
