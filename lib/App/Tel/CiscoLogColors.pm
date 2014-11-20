# this is only intended as an example.  Most people have their own ideas of
# what's important and what isn't in a log, so you'll want to highlight lines
# differently.

package App::Tel::CiscoLogColors;
#use parent 'ColorObject';
use Term::ANSIColor;
use strict;

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
    s/((%SEC-6-IPACCESSLOGS|%SNMP-3-AUTHFAIL|%PFINIT-SP-5-CONFIG_SYNC).*)/sprintf("%s", colored($1, 'green'))/eg;
    s/((%SYS-5-CONFIG_I|%CONTROLLER-5-UPDOWN).*)/sprintf("%s", colored($1, 'red'))/eg;
    return $_;
}

1;
