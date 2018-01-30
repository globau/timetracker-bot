package TimeTracker::Edits;
use Moo;

use TimeTracker::DB;
use TimeTracker::Edit;

has _list   => ( is => 'rw', default => sub { [] } );

sub load {
    my ($class, $user, $date) = @_;
    my $dbh = TimeTracker::DB->instance;

    $date = $date->clone->set_time_zone('UTC');

    my @rows = $dbh->selectall_hash(
        "SELECT * FROM edits WHERE nick=? AND dt=?",
        $user->nick, $date->as_sql,
    );
    my @list;
    foreach my $row (@rows) {
        $row->{date} = DateTime->from_sql($row->{dt});
        push @list, TimeTracker::Edit->new($row);
    }
    return $class->new(_list => \@list);
}

sub add {
    my ($self, %args) = @_;
    my @list = @{ $self->_list };
    if (exists $args{edit}) {
        push @list, $args{edit};
    } else {
        push @list, TimeTracker::Edit->new(%args);
    }
    @list = sort { $a->date <=> $b->date } @list;
    $self->_list(\@list);
}

sub each {
    my ($self) = @_;
    return @{ $self->_list };
}

sub minutes {
    my ($self) = @_;
    my $result = 0;
    foreach my $edit ($self->each) {
        $result += $edit->minutes;
    }
    return $result;
}

1;
