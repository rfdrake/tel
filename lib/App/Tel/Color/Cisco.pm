package App::Tel::Color::Cisco;
use parent 'App::Tel::Color::Base';
use Term::ANSIColor;
use Scalar::Util qw ( looks_like_number );
use strict;
use warnings;

=head1 NAME

App::Tel::Cisco - Colors for show interface and other commands

=head2 METHODS

=cut

sub _c {
    # if not a number then return the original text
    my $val = shift;
    return $val if (!looks_like_number($val));
    if ($val > 0) {
        return colored($val, 'red');
    }
    return colored($val, 'green');
}


# not kidding, this will be crazy.
# it simulates s/blah (\d+) blah/sprintf("blah %s blah", c($1))/e;
sub _crazy {
    my $text = shift;
    my @strings = @_;

    foreach my $s (@strings) {
        my $substring = $s;
        # (?<!\\)(?!\\) are funny things that mean look behind and look ahead
        # for \\ (the escape \ before a parenthesis)
        my $count = $substring =~ s/(?<!\\)(?!\\)\(.*?\)/%s/g;

        my $args = '';
        for (1..$count) { $args .= ",_c(\$$_)" }

        my $eval = 'sprintf("'.$substring.'"'.$args.')';

        # in theory this is safer than the old external eval.  The reason
        # being all the evaluated data is part of the defined strings passed
        # to the _crazy function.  That means no data coming from a router can
        # be evaluated.
        $text =~ s/$s/eval $eval/e;
    }

    return $text;
}

sub _uspwr {
    my $pwr = shift;
    my $color = 'red';
    if    ( $pwr < 30 ) { $color = 'red'; }
    elsif ( $pwr >= 30 && $pwr <= 33 ) { $color = 'yellow'; }
    elsif ( $pwr >= 33 && $pwr <= 45 ) { $color = 'green'; }
    elsif ( $pwr >= 45 && $pwr <= 50 ) { $color = 'yellow'; }
    elsif ( $pwr > 50 ) { $color = 'red'; }
    return colored($pwr, $color);
}

sub _ussnr {
    my $snr = shift;
    my $color = 'red';
    if    ( $snr < 20 ) { $color = 'red'; }
    elsif ( $snr >= 20 && $snr <= 25 ) { $color = 'yellow'; }
    elsif ( $snr > 25 ) { $color = 'green'; }
    return colored($snr, $color);
}

sub _dspwr {
    my $input = shift;
    my $pwr = $input;
    $pwr =~ s/ //g;   # remove all spaces, leaving possible negative sign and value
    my $color = 'red';
    if    ( $pwr < -15 ) { $color = 'red'; }
    elsif ( $pwr >= -15 && $pwr <= -9 ) { $color = 'yellow'; }
    elsif ( $pwr >= -9 && $pwr <= 9 ) { $color = 'green'; }
    elsif ( $pwr >= 9 && $pwr <= 15 ) { $color = 'yellow'; }
    elsif ( $pwr > 15 ) { $color = 'red'; }
    return colored($input, $color);
}

sub _dssnr {
    my $snr = shift;
    my $color = 'red';
    if ( $snr eq '-----' ) { $color = 'yellow'; }
    elsif ( $snr < 35 ) { $color = 'red'; }
    elsif ( $snr >= 35 && $snr <= 35 ) { $color = 'yellow'; }
    elsif ( $snr > 35 ) { $color = 'green'; }
    return colored($snr, $color);
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
    my ($self, $text) = @_;

    $text =~s/(\S+) is (.*), line protocol is (\S+)/sprintf("%s is %s, line protocol is %s", colored($1, 'magenta'),
            _interface($2), _interface($3))/eg;

    # sh cable modem phy
    $text =~ s#([a-f0-9\.]+ C\d+/\d+/U\d+\s+\d+\s+)([\d\.]+)(\s+)([\d\.]+)(\s+\!?\d+)([\s\-]+[\d\.]+)(\s+)([\d\.\-]+)#
        sprintf("%s%s%s%s%s%s%s%s", $1, _uspwr($2), $3, _ussnr($4), $5, _dspwr($6), $7, _dssnr($8))#eg;

    # more show interface
    $text =~ s/Full-duplex/colored('Full-duplex', 'green')/eg;
    $text =~ s/Half-duplex/colored('Half-duplex', 'yellow')/eg;

    # sh proc cpu
    $text =~ s#(\s+\d+\s+\d+\s+\d+\s+\d+\s+)([\d\.]+)(%\s+)([\d\.]+)(%\s+)([\d\.]+)#
        sprintf("%s%s%s%s%s%s", $1, _cpu($2), $3, _cpu($4), $5, _cpu($6))#eg;

    # 4500x sh proc cpu
    $text =~ s#(\d+\s+\d+\s+\d+\s+\d+\s+)([\d\.]+)(\s+)([\d\.]+)(\s+)([\d\.]+)#
        sprintf("%s%s%s%s%s%s", $1, _cpu($2), $3, _cpu($4), $5, _cpu($6))#eg;

    # parts of sh run
    if ($text =~ /^(ip|ipv6) route /) {
        $text = colored($text, 'yellow');
    } elsif ($text =~ /^aaa/) {
        $text = colored($text, 'green');
    } elsif ($text =~ /^(?:(?:no )?tacacs-server|radius-server|ntp)/) {
        $text = colored($text, 'magenta');
    } elsif ($text =~ /^(?:mac )?access-list/) {
        $text = colored($text, 'cyan');
    } elsif ($text =~ /^snmp-server/) {
        $text = colored($text, 'bright_white');
    }

    $text = _crazy($text,
        '(\d+) runts, (\d+) giants, (\d+) throttles',
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

    return $text;
}

1;
