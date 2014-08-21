#!/usr/bin/perl
use Moo;

BEGIN { $ENV{TZ} = 'UTC' }

use FindBin qw($RealBin);
use lib $RealBin;

use DateTime;
use TimeTracker::Commands;
use TimeTracker::Config;

my ($nick, @command) = @ARGV;
($nick && scalar(@command))
    or die "syntax: command <nick> <command>\n";
my $command = join(' ', @command);

my $commands = TimeTracker::Commands->instance;

eval {
    my $response = $commands->handle($nick, $command);
    foreach my $line (@$response) {
        print "$line\n";
    }
};
if ($@) {
    my $error = "$@";
    $error =~ s/(^\s+|\s+$)//g;
    print "error: $error\n";
}
