package TimeTracker::Commands;
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
use strict;
use v5.10;
use warnings;

use File::Spec;
use FindBin qw( $Bin );
use List::Util qw( any );
use Moo;
use Try::Tiny qw( catch try );

has _handler_files => (is => 'rw', default => sub { [] });
has handlers => (is => 'lazy');

sub _build_handlers {
    my ($self) = @_;

    my $handlers = [];

    my (undef, $dir) = File::Spec->splitpath(__FILE__);
    foreach my $file (glob("${dir}Command/*.pm")) {
        my (undef, undef, $class) = File::Spec->splitpath($file);
        next if $class eq 'Base.pm';
        push @{ $self->_handler_files }, $file
            unless any { $_ eq $file } @{ $self->_handler_files };

        try {
            require $file;
            $class =~ s/\.pm$//;
            $class = "TimeTracker::Command::$class";
            push @{$handlers}, $class->new();
        }
        catch {
            print STDERR "$_\n";
        };
    }

    return [sort { $a->triggers->[0] cmp $b->triggers->[0] } @{$handlers}];
}

sub execute {
    my ($self, $nick, $command_line) = @_;

    my ($handler, $args) = $self->_get_handler($command_line);
    return [] unless defined($handler);
    return ['huh?'] unless $handler;

    my $response;
    try {
        $response = $handler->execute($nick, $args);
    }
    catch {
        my $error = $_;
        $error =~ s/(^\s+|\s+$)//g;
        $response = ["error: $error"];
    };
    return $response;
}

sub handler_for {
    my ($self, $command) = @_;
    $command = lc($command);
    foreach my $handler (@{ $self->handlers }) {
        return $handler if any { $_ eq $command } @{ $handler->triggers };
    }
    return undef;
}

sub _get_handler {
    my ($self, $command_line) = @_;

    $command_line =~ s/(^\s+|\s+$)//g;
    $command_line =~ s/\s+/ /g;
    $command_line =~ s/^!//;

    return undef
        unless $command_line =~ s/^(\S+)\s+//
        || $command_line =~ s/^(.+)$//;
    my $command = $1;
    $command_line = undef if $command_line eq '';

    foreach my $handler (@{ $self->handlers }) {
        return ($handler, $command_line)
            if $handler->handles($command);
    }
    return (0);
}

#
# singleton
#

my $_instance;

sub instance {
    my ($class, @args) = @_;
    return defined $_instance ? $_instance : ($_instance = $class->new(@args));
}

1;
