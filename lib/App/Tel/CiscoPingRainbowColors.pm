# test code for chainloading and things

package App::Tel::CiscoPingRainbowColors;
use Term::ANSIColor;
use strict;

$Term::ANSIColor::AUTORESET++;         # reset color after each print
$SIG{INT} = sub { print "\n"; exit; }; # reset color after Ctrl-C

my @colors = qw ( GREEN YELLOW BLUE MAGENTA CYAN WHITE );

# Bright colors were added after 3.00
if ($Term::ANSIColor::VERSION >= 3.00) {
    push(@colors, qw (
      BRIGHT_GREEN    BRIGHT_YELLOW
      BRIGHT_BLUE     BRIGHT_MAGENTA    BRIGHT_CYAN     BRIGHT_WHITE
    ));
}

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
    return colored(shift, $colors[$self->{current_color}++ % scalar(@colors)]);
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
