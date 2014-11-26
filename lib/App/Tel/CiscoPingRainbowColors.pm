package App::Tel::CiscoPingRainbowColors;
use parent 'App::Tel::ColorObject';
use Term::ANSIColor;
use strict;
use warnings;

our $VERSION = eval '0.1';


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return bless( {
        'current_color' => 0,
        'ping' => 0,
    }, $class);
}

sub next_color {
    my $self = shift;
    return colored(shift, $App::Tel::ColorObject::colors[$self->{current_color}++ % scalar(@App::Tel::ColorObject::colors)]);
}

sub colorize {
    my $self = shift;
    $_ = shift;

    # We need to define a start point in the buffer that the dot regex isn't
    # allowed to search before so that this line and ones before it with
    # dots don't get red dots.
    if (/Sending \d+, \d+-byte ICMP Echos to/) {
        $self->{ping}=1;
    }

    if ($self->{ping}) {
            s/(\!)/$self->next_color($1)/eg;
            s/(\.)/colored('.', 'red')/eg;
        if (/Success rate is/) {
            $self->{ping}=0;
            $self->{current_color}=0;
        }
    }
    return $_;
}

1;
