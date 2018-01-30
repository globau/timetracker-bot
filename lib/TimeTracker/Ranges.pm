package TimeTracker::Ranges;
use Moo;

use TimeTracker::Range;

has _list   => ( is => 'rw', default => sub { [] } );

sub add {
    my ($self, %args) = @_;
    my @list = @{ $self->_list };
    if (exists $args{range}) {
        push @list, $args{range};
    } else {
        push @list, TimeTracker::Range->new(%args);
    }
    @list = sort { $a->start <=> $b->start } @list;
    $self->_list(\@list);
}

sub each {
    my ($self) = @_;
    return @{ $self->_list };
}

sub start {
    my ($self) = @_;
    return unless @{ $self->_list };
    return $self->_list->[0]->start;
}

sub end {
    my ($self) = @_;
    return unless @{ $self->_list };
    return $self->_list->[scalar(@{ $self->_list }) - 1]->end;
}

sub set_time_zone {
    my ($self, $time_zone) = @_;
    foreach my $range (@{ $self->_list }) {
        $range->set_time_zone($time_zone);
    }
}

sub split_into_days {
    my ($self) = @_;
    foreach my $range ($self->each) {
        while ($range->start->ymd ne $range->end->ymd) {
            # end of the start date
            my $new_end = $range->start
                ->clone
                ->truncate(to => 'day')
                ->add(days => 1)
                ->add(minutes => -1);
            my $new_start = $new_end->clone->add(minutes => 1);
            my $old_end = $range->end;
            $range->end($new_end);
            $range = TimeTracker::Range->new(start => $new_start, end => $old_end);
            $self->add(range => $range);
        }
    }
}

sub format_cldr {
    my ($self, $format) = @_;
    my ($start, $end) = ($self->start, $self->end);
    return ''
        unless $start;
    return $start->format_cldr($format)
        unless $end;
    return $start->format_cldr($format) . ' - ' . $end->format_cldr($format);
}

1;
