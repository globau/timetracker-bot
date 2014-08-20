package TimeTracker::Commands;
use Moo;

use FindBin qw($Bin);
use File::Spec;
use Module::Refresh;

has _handler_files => ( is => 'rw', default => sub { [] } );
has _refresher     => ( is => 'lazy' );

sub refresh_handlers {
    my ($self) = @_;

    foreach my $file (@{ $self->_handler_files }) {
        $self->_refresher->refresh_module($file);
    }
}

sub handlers {
    my ($self) = @_;
    my $handlers = [];

    my (undef, $dir) = File::Spec->splitpath(__FILE__);
    foreach my $file (glob("${dir}Command/*.pm")) {
        my (undef, undef, $class) = File::Spec->splitpath($file);
        next if $class eq 'Base.pm';
        push @{ $self->_handler_files }, $file
            unless grep { $_ eq $file } @{ $self->_handler_files };
        require $file;

        $class =~ s/\.pm$//;
        $class = "TimeTracker::Command::$class";
        push @$handlers, $class->new();
        my $object = $class->new();
    }

    $handlers = [ sort { $a->triggers->[0] cmp $b->triggers->[0] } @$handlers ];
    return $handlers;
}

sub execute {
    my ($self, $nick, $command_line) = @_;

    my ($handler, $args) = $self->_get_handler($command_line);
    return unless defined($handler);

    if ($handler) {
        my $execute = sprintf("'%s' '%s' '%s' '%s'",
            _esc(TimeTracker::Config->instance->command_file),
            _esc($nick),
            _esc($handler->command),
            _esc($args)
        );
        my @response = `$execute 2>&1`;
        chomp(@response);
        return \@response;
    } else {
        return [ 'huh?' ];
    }
}

sub handle {
    my ($self, $nick, $command_line) = @_;

    my ($handler, $args) = $self->_get_handler($command_line);
    return unless defined($handler);

    if ($handler) {
        return $handler->execute($nick, $args);
    } else {
        return [ 'huh?' ];
    }
}

sub handler_for {
    my ($self, $command) = @_;
    $command = lc($command);
    foreach my $handler (@{ $self->handlers }) {
        return $handler if grep { $_ eq $command } @{ $handler->triggers };
    }
    return undef;
}

sub _get_handler {
    my ($self, $command_line) = @_;

    $command_line =~ s/(^\s+|\s+$)//g;
    $command_line =~ s/\s+/ /g;
    $command_line =~ s/^!//;

    return undef unless
        $command_line =~ s/^(\S+)\s+//
        || $command_line =~ s/^(.+)$//;
    my $command = $1;
    $command_line = undef if $command_line eq '';

    foreach my $handler (@{ $self->handlers }) {
        return ($handler, $command_line)
            if $handler->handles($command);
    }
    return (0);
}

sub _build__refresher {
    return Module::Refresh->new();
}

sub _esc {
    my ($str) = @_;
    return '' unless defined $str;
    $str =~ s/'/\\'/g;
    $str =~ s/[\r\n]+/ /g;
    return $str;
}

#
# singleton
#

my $_instance;
sub instance {
    my $class = shift;
    return defined $_instance ? $_instance : ($_instance = $class->new(@_));
}

1;
