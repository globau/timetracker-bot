package TimeTracker::IRC;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
## no critic (Subroutines::RequireArgUnpacking)
use strict;
use v5.10;
use warnings;

use DateTime ();
use Moo;
use POE::Component::IRC::Plugin::BotAddressed ();
use POE::Component::IRC::Plugin::Connector    ();
use POE::Component::IRC::Plugin::CycleEmpty   ();
use POE::Component::IRC::Plugin::NickServID   ();
use POE::Component::IRC::State                ();
use POE;
use TimeTracker::Commands ();
use TimeTracker::Config   ();
use TimeTracker::User     ();
use TimeTracker::Util qw( canon_nick );

my $_irc;

sub irc {
    return $_irc;
}

sub start {
    my $config = TimeTracker::Config->instance;
    $_irc = POE::Component::IRC::State->spawn(
        nick       => $config->irc_nick,
        ircname    => $config->irc_name,
        server     => $config->irc_host,
        port       => $config->irc_port,
        awaypoll   => 60,
        debug      => 1,
        whojoiners => 0,
    ) or die "failed: $!\n";

    $_irc->plugin_add(
        'NickServID',
        POE::Component::IRC::Plugin::NickServID->new(
            Password => $config->irc_password,
        )
    ) if $config->irc_password;

    $_irc->plugin_add('CycleEmtpy', POE::Component::IRC::Plugin::CycleEmpty->new());

    $_irc->plugin_add('BotAddressed', POE::Component::IRC::Plugin::BotAddressed->new());

    POE::Session->create(
        package_states => [
            'TimeTracker::IRC' => [
                qw(
                    _start
                    irc_001
                    irc_away_sync_end
                    irc_chan_sync
                    irc_bot_addressed
                    irc_msg
                    irc_public
                    )
            ],
        ],
        heap => { irc => $_irc },
    );

    $poe_kernel->run();
}

#
# poe handlers
#

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $irc    = $heap->{irc};
    my $config = TimeTracker::Config->instance;
    $irc->yield(register => 'all');
    $heap->{connector} = POE::Component::IRC::Plugin::Connector->new();
    $irc->plugin_add('Connector' => $heap->{connector});

    $irc->yield(
        connect => {
            Server => $config->irc_host,
            Port   => $config->irc_port,
            Nick   => $config->irc_nick,
        }
    );
}

sub irc_001 {
    my ($kernel, $sender) = @_[KERNEL, SENDER];
    my $irc    = $sender->get_heap();
    my $config = TimeTracker::Config->instance;
    $irc->yield(join => $config->irc_channel);
}

sub irc_chan_sync {
    my ($kernel, $sender, $channel) = @_[KERNEL, SENDER, ARG0];
    my $irc = $sender->get_heap();
    _track_time($kernel, $irc, $channel);
}

sub irc_away_sync_end {
    my ($kernel, $sender, $channel) = @_[KERNEL, SENDER, ARG0];
    my $irc = $sender->get_heap();
    _track_time($kernel, $irc, $channel);
}

sub irc_msg {
    my ($kernel, $sender, $heap) = @_[KERNEL, SENDER, HEAP];
    my $irc  = $sender->get_heap();
    my $nick = (split /!/, $_[ARG0])[0];
    my $what = $_[ARG2];
    _command($kernel, $irc, $nick, $nick, $what);
}

sub irc_public {
    my ($kernel, $sender, $heap) = @_[KERNEL, SENDER, HEAP];
    my $irc     = $sender->get_heap();
    my $nick    = (split /!/, $_[ARG0])[0];
    my $channel = $_[ARG1]->[0];
    my $what    = $_[ARG2];
    if ($what =~ s/^!//) {
        _command($kernel, $irc, $channel, $nick, $what);
    }
}

sub irc_bot_addressed {
    my ($kernel, $sender, $heap) = @_[KERNEL, SENDER, HEAP];
    my $irc     = $sender->get_heap();
    my $nick    = (split /!/, $_[ARG0])[0];
    my $channel = $_[ARG1]->[0];
    my $what    = $_[ARG2];
    _command($kernel, $irc, $channel, $nick, $what);
}

#
# action handlers
#

sub _track_time {
    my ($kernel, $irc, $channel) = @_;
    my $config = TimeTracker::Config->instance;

    my $now = DateTime->now();
    foreach my $nick ($irc->channel_list($channel)) {
        next if $nick eq $config->irc_nick || $nick eq 'timetracker';
        next unless TimeTracker::User->registered($nick);
        my $user = TimeTracker::User->new(nick => $nick);
        if ($irc->is_away($nick)) {
            $user->last_status('A');
        } else {
            $user->last_status('O');
            $user->log_active($now);
        }
        $user->commit();
    }
}

sub _command {
    my ($kernel, $irc, $channel, $nick, $what) = @_;
    my $config   = TimeTracker::Config->instance;
    my $commands = TimeTracker::Commands->instance;

    next if $nick eq $config->irc_nick || $nick eq 'timetracker';

    my $response = $commands->execute($nick, $what);
    return unless $response && @{$response};

    # if the command returns '@private' as the first line
    # then always send the response off-channel
    if ($response->[0] eq '@private') {  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
        shift @{$response};
        $channel = $nick;
    }

    $response->[0] = $nick . ', ' . $response->[0]
        if $channel =~ /^#/;
    foreach my $line (@{$response}) {
        $kernel->post($irc => privmsg => $channel => $line);
    }
}

1;
