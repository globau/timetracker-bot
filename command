#!/usr/bin/perl
use local::lib;
use strict;
use warnings;
use v5.10;

use FindBin qw($RealBin);
use lib "$RealBin/lib";

BEGIN { $ENV{TZ} = 'UTC' }

use DateTime;
use TimeTracker::Commands;
use TimeTracker::Config;

my ($nick, @command) = @ARGV;
($nick && scalar(@command))
    or die "syntax: command <nick> <command>\n";
my $command = join(' ', @command);

my $commands = TimeTracker::Commands->instance;
foreach my $line (@{ $commands->execute($nick, $command) }) {
    print "$line\n";
}
