package TimeTracker::Command::Edits;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use Moo;
use TimeTracker::Edits ();
use TimeTracker::User  ();

extends 'TimeTracker::Command::Base';

sub _build_triggers {
    return [qw( edits )];
}

sub _build_help_short {
    return 'show adjustments';
}

sub _build_help_long {
    return ['syntax: edits date', 'shows all your edits for the specified date.',];
}

sub execute {
    my ($self, $nick, $args) = @_;
    my $user = TimeTracker::User->load($nick);

    my $date = $self->parse_date($user, $args);
    $date->truncate(to => 'day');

    my @response;
    my $edits = TimeTracker::Edits->load($user, $date);
    foreach my $edit ($edits->iter) {
        push @response, scalar($edit);
    }

    if (@response) {
        unshift @response, 'edits for ' . $date->format_cldr('d MMM') . ':';
    } else {
        push @response, 'no edits for ' . $date->format_cldr('d MMM');
    }
    return \@response;
}

1;
