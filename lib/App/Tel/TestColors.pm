# test code for chainloading and things

package App::Tel::TestColors;
use Term::ANSIColor;
use strict;
use warnings;

our $VERSION = eval '0.1';

$Term::ANSIColor::AUTORESET++;         # reset color after each print
$SIG{INT} = sub { print "\n"; exit; }; # reset color after Ctrl-C

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return bless( {}, $class);
}

sub colorize {

    my $self = shift;
    $_ = shift;
    s/(.*#)/sprintf("%s", colored($1, 'magenta'))/eg;
    return $_;
}

1;
