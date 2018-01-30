package TimeTracker::Command::Hours;
use Moo;
extends 'TimeTracker::Command::Base';

use TimeTracker::User;

sub _build_triggers {[ qw( hours work ) ]}

sub _build_help_short {
    'displays/sets the number of hours you work per week'
}
sub _build_help_long {[
    'syntax: hours [hours]',
    'displays or sets the number of hours you work per week.',
    'the default is 40 hours per week.',
]}

sub execute {
    my ($self, $nick, $args) = @_;

    my $user = TimeTracker::User->load($nick);

    if (!$args) {
        return [ $user->work_week . ' hours/week' ];
    } else {
        die "invalid value for hours per week\n"
            if $args !~ /^\d+(.\d+)?$/ || $args <= 0;
        $user->work_week($args);
        $user->commit();
        return [ "hours/week updated to $args" ];
    }
}

1;
