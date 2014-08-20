package TimeTracker::Command::Edits;
use Moo;
extends 'TimeTracker::Command::Base';

use TimeTracker::Edits;
use TimeTracker::User;
use TimeTracker::Util;

sub _build_triggers {[ qw( edits ) ]}

sub _build_help_short {
    'show adjustments'
}
sub _build_help_long {[
    'syntax: edits date',
    'shows all your edits for the specified date.'
]}

sub execute {
    my ($self, $nick, $args) = @_;
    my $user = TimeTracker::User->load($nick);

    my $date = $self->parse_date($user, $args);
    $date->truncate(to => 'day');

    my @response;
    my $edits = TimeTracker::Edits->load($user, $date);
    foreach my $edit ($edits->each) {
        push @response, scalar($edit);
    }

    if (@response) {
        unshift @response, "edits for " . $date->format_cldr('d MMM') . ":";
    } else {
        push @response, "no edits for " . $date->format_cldr('d MMM');
    }
    return \@response;
}

1;
