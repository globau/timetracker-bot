package TimeTracker::Edit;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use Moo;
use TimeTracker::DB   ();
use TimeTracker::User ();
use TimeTracker::Util qw( canon_nick format_minutes );

use overload '""' => '_as_string';

has nick => (is => 'ro', required => 1, coerce => \&_coerce_nick);
has date => (is => 'ro', required => 1, coerce => \&_coerce_date);
has minutes => (is => 'ro', required => 1);
has reason  => (is => 'ro', required => 1);

has _user_date => (is => 'lazy');

sub _coerce_nick {
    my ($nick) = @_;
    return canon_nick($nick);
}

sub _coerce_date {
    my ($date) = @_;
    return $date->clone->set_time_zone('UTC');
}

sub _build__user_date {
    my ($self) = @_;
    my $user = TimeTracker::User->load($self->nick);
    return $self->date->clone->set_time_zone($user->time_zone);
}

sub _as_string {
    my ($self) = @_;
    return sprintf(q{%s by %s '%s'},
        $self->_user_date->format_cldr('d MMM yy'),
        format_minutes($self->minutes, 1),
        $self->reason,);
}

sub commit {
    my ($self) = @_;
    my $dbh = TimeTracker::DB->instance;

    $dbh->do('INSERT INTO edits(nick, dt, minutes, reason) VALUES(?, ?, ?, ?)',
        undef, $self->nick, $self->date->as_sql, $self->minutes, $self->reason,);
}

1;
