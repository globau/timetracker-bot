package TimeTracker::Command::Base;
use Moo;

use TimeTracker::Util;

has triggers    => ( is => 'lazy' );

has help_short  => ( is => 'lazy' );
has help_long    => ( is => 'lazy' );

sub command {
    my ($self) = @_;
    return $self->triggers->[0];
}

sub handles {
    my ($self, $trigger) = @_;
    $trigger = lc($trigger);
    return (grep { $_ eq $trigger } @{ $self->triggers}) ? 1 : 0;
}

sub today {
    my ($self, $user) = @_;
    return DateTime->now
           ->set_time_zone($user->time_zone)
           ->truncate(to => 'day');
}

sub parse_date {
    my ($self, $user, $args, $scope) = @_;

    my $date;
    if ($args) {
        $args = "last $scope"
            if $args eq 'last';
        my $parser = DateTime::Format::Natural->new(
            time_zone   => $user->time_zone,
            format      => 'y/m/d',
        );
        $date = $parser->parse_datetime($args);
        die $parser->error . "\n"
            unless $parser->success;
    } else {
        $date = DateTime->now
                ->set_time_zone($user->time_zone);
    }
    $date->truncate(to => 'day');

    return $date;
}

sub format_response {
    my ($self, %args) = @_;
    my $hour_width = $args{wide} ? 3 : 2;
    my @response;

    push @response, format_minutes($args{minutes}, $args{signed}, $hour_width);
    push @response, $args{caption} if $args{caption};
    if (exists $args{target}) {
        my $target;
        if ($args{minutes} == $args{target}) {
            $target = '00:00';
        } elsif ($args{minutes} < $args{target}) {
            $target = '-' . format_minutes($args{target} - $args{minutes});
        } else {
            $target = '+' . format_minutes($args{minutes} - $args{target});
        }
        push @response, '[' . $target . ']';
    }
    push @response, $args{extra} if $args{extra};
    return join(' ', @response);
}

1;
