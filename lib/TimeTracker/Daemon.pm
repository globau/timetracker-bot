package TimeTracker::Daemon;
use strict;
use v5.10;
use warnings;

use Carp qw( confess );
use Daemon::Generic;
use List::Util qw( any );
use TimeTracker::Config;
use TimeTracker::IRC;

sub start {
    $SIG{__DIE__} = sub { confess(@_) };
    newdaemon();
}

sub gd_preconfig {
    my ($self) = @_;
    return (pidfile => TimeTracker::Config->instance->pid_file,);
}

sub gd_getopt {
    my ($self) = @_;
    if (any { $_ eq '-d' } @ARGV) {
        @ARGV = qw(-f start);
        TimeTracker::Config->instance->debug(1);
    }
    $self->SUPER::gd_getopt();
}

sub gd_redirect_output {
    my ($self) = @_;
    my $filename = TimeTracker::Config->instance->log_file;
    open(STDERR, '>>', $filename)
        or die "could not open stderr: $!";
    close(STDOUT) or die $!;
    open(STDOUT, '>&STDERR')
        or die "redirect STDOUT -> STDERR: $!";
}

sub gd_run {
    my ($self) = @_;
    TimeTracker::IRC->start();
}

1;
