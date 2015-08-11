package App::Tel::CiscoColors;
use parent 'App::Tel::ColorObject';
use Term::ANSIColor;
use strict;
use warnings;

=head1 NAME

App::Tel::CiscoColors - Colors for show interface and other commands

=head2 METHODS

=cut

sub _c {
    # if not a number then return the original text
    my $val = shift;
    return $val if ($val =~ /\D/);
    if ($val > 0) {
        return colored($val, 'red');
    }
    return colored($val, 'green');
}


# not kidding, this will be crazy.
# it simulates s/blah (\d+) blah/sprintf("blah %s blah", c($1))/e;
sub _crazy {
    my @strings = @_;
    my $evils;

    foreach my $s (@strings) {
        my $substring = $s;
        # (?<!\\)(?!\\) are funny things that mean look behind and look ahead
        # for \\ (the escape \ before a parenthesis)
        my $count = $substring =~ s/(?<!\\)(?!\\)\(.*?\)/%s/g;

        my $args;
        map { $args .= ",_c(\$$_)"; } 1..$count;
        $evils .= "s/$s/sprintf(\"$substring\"$args)/e;";
    }

    return $evils;
}

sub _uspwr {
    my $pwr = shift;
    my $color = 'red';
    if ( $pwr < 30 ) { $color = 'red'; }
    if ( $pwr >= 30 && $pwr <= 33 ) { $color = 'yellow'; }
    if ( $pwr >= 33 && $pwr <= 45 ) { $color = 'green'; }
    if ( $pwr >= 45 && $pwr <= 50 ) { $color = 'yellow'; }
    if ( $pwr > 50 ) { $color = 'red'; }
    return colored($pwr, $color);
}

sub _ussnr {
    my $pwr = shift;
    my $color = 'red';
    if ( $pwr < 20 ) { $color = 'red'; }
    if ( $pwr >= 20 && $pwr <= 25 ) { $color = 'yellow'; };
    if ( $pwr > 25 ) { $color = 'green'; }
    return colored($pwr, $color);
}

sub _dspwr {
    my $input = shift;
    my $pwr = $input;
    $pwr =~ s/ //g;   # remove all spaces, leaving possible negative sign and value
    my $color = 'red';
    if ( $pwr < -15 ) { $color = 'red'; }
    if ( $pwr >= -15 && $pwr <= -9 ) { $color = 'yellow'; }
    if ( $pwr >= -9 && $pwr <= 9 ) { $color = 'green'; }
    if ( $pwr >= 9 && $pwr <= 15 ) { $color = 'yellow'; }
    if ( $pwr > 15 ) { $color = 'red'; }
    return colored($input, $color);
}

sub _dssnr {
    my $pwr = shift;
    my $color = 'red';
    if ( $pwr eq '-----' ) { $color = 'yellow'; }
    elsif ( $pwr < 35 ) { $color = 'red'; }
    elsif ( $pwr >= 35 && $pwr <= 35 ) { $color = 'yellow'; }
    elsif ( $pwr > 35 ) { $color = 'green'; }
    return colored($pwr, $color);
}

sub _cpu {
    my $cpu = shift;
    my $color = 'green';
    if ($cpu > 0) { $color = 'yellow'; }
    if ($cpu > 1) { $color = 'red'; }
    return colored($cpu, $color);
}

sub _interface {
    # without knowing syntax, this will automatically handle err-disable and
    # any other weird corner cases by defaulting to red.
    my $color = 'red';
    if ($_[0] eq 'up') {
        $color = 'green';
    }
    return colored($_[0], $color);
}

=head2 colorize

    my $output = $self->colorize($input);

Given a line of text from a cisco router, this will try to colorize it.

=cut

sub colorize {
    my $self = shift;
    $_ = shift;

    s/(\S+) is (.*), line protocol is (\S+)/sprintf("%s is %s, line protocol is %s", colored($1, 'magenta'),
            _interface($2), _interface($3))/eg;

    # sh cable modem phy
    s#([a-f0-9\.]+ C\d+/\d+/U\d+\s+\d+\s+)([\d\.]+)(\s+)([\d\.]+)(\s+\!?\d+)([\s\-]+[\d\.]+)(\s+)([\d\.\-]+)#
        sprintf("%s%s%s%s%s%s%s%s", $1, _uspwr($2), $3, _ussnr($4), $5, _dspwr($6), $7, _dssnr($8))#eg;

    # more show interface
    s/Full-duplex/colored('Full-duplex', 'green')/eg;
    s/Half-duplex/colored('Half-duplex', 'yellow')/eg;

    # sh proc cpu
    s#(\s+\d+\s+\d+\s+\d+\s+\d+\s+)([\d\.]+)(%\s+)([\d\.]+)(%\s+)([\d\.]+)#
        sprintf("%s%s%s%s%s%s", $1, _cpu($2), $3, _cpu($4), $5, _cpu($6))#eg;

    # parts of sh run
    s/\n(ip route [^\n]+)/sprintf("\n%s", colored($1,'yellow'))/eg;
    s/\n(ipv6 route [^\n]+)/sprintf("\n%s", colored($1,'yellow'))/eg;
    s/\n(aaa [^\n]+)/sprintf("\n%s", colored($1,'green'))/eg;
    s/\n(access-list [^\n]+)/sprintf("\n%s", colored($1,'cyan'))/eg;
    s/\n(snmp-server [^\n]+)/sprintf("\n%s", colored($1,'bright_white'))/eg;
    s/\n(tacacs-server [^\n]+)/sprintf("\n%s", colored($1,'magenta'))/eg;
    s/\n(no tacacs-server [^\n]+)/sprintf("\n%s", colored($1,'magenta'))/eg;
    s/\n(radius-server [^\n]+)/sprintf("\n%s", colored($1,'magenta'))/eg;
    s/\n(ntp [^\n]+)/sprintf("\n%s", colored($1,'magenta'))/eg;

    my $regexp = _crazy('(\d+) runts, (\d+) giants, (\d+) throttles',
        '(\d+) input errors, (\d+) CRC, (\d+) frame, (\d+) overrun, (\d+) ignored',
        '(\d+) input packets with dribble condition detected',
        'Total output drops: (\d+)',
        '(\d+) output errors, (\d+) interface resets',
        '(\d+) output errors, (\d+) collisions, (\d+) interface resets',
        '(\d+) output buffer failures, (\d+) output buffers swapped out',
        '(\d+) carrier transitions',
        'Output queue (\S+), (\d+) drops; input queue (\S+), (\d+) drops',
        '(\d+)\/(\d+) \(size\/max\/drops\/flushes\)\;',
        '(\d+) (pause input|watchdog|underruns|no buffer|pause output|abort)',
        '(\d+) output errors, (\d+) collisions, (\d+) interface resets',
        '(\d+) babbles, (\d+) late collision, (\d+) deferred',
        '(\d+) lost carrier, (\d+) no carrier',
    );

    # the rest of show interface is in this eval
    eval $regexp; ## no critic
    return $_;
}

1;
