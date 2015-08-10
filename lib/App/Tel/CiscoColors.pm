package App::Tel::CiscoColors;
use parent 'App::Tel::ColorObject';
use Term::ANSIColor;
use strict;
use warnings;

# not kidding, this will be crazy.
# it simulates s/blah (\d+) blah/sprintf("blah %s blah", c($1))/e;
sub crazy {
   my @strings = @_;
   my $evils;

    my $c = sub {
       return $_[0] if ($_[0] =~ /\D/);
       if ($_[0] > 0) {
          return colored($_[0], 'red');
       } else {
          return colored($_[0], 'green');
       }
    };


   foreach my $s (@strings) {

      my $substring = $s;
      # (?<!\\)(?!\\) are funny things that mean look behind and look ahead
      # for \\ (the escape \ before a parenthesis)
      my $count = $substring =~ s/(?<!\\)(?!\\)\(.*?\)/%s/g;

      my $args;
      map { $args .= ",$c->(\$$_)"; } 1..$count;
      $evils .= "s/$s/sprintf(\"$substring\"$args)/e;";
   }

   return $evils;
}

sub uspwr {
    my $pwr = shift;
    my $color = 'red';
    if ( $pwr < 30 ) { $color = 'red'; }
    if ( $pwr >= 30 && $pwr <= 33 ) { $color = 'yellow'; }
    if ( $pwr >= 33 && $pwr <= 45 ) { $color = 'green'; }
    if ( $pwr >= 45 && $pwr <= 50 ) { $color = 'yellow'; }
    if ( $pwr > 50 ) { $color = 'red'; }
    return colored($pwr, $color);
}

sub ussnr {
    my $pwr = shift;
    my $color = 'red';
    if ( $pwr < 20 ) { $color = 'red'; }
    if ( $pwr >= 20 && $pwr <= 25 ) { $color = 'yellow'; };
    if ( $pwr > 25 ) { $color = 'green'; }
    return colored($pwr, $color);
}
sub dspwr {
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
sub dssnr {
    my $pwr = shift;
    my $color = 'red';
    if ( $pwr eq '-----' ) { $color = 'yellow'; }
    elsif ( $pwr < 35 ) { $color = 'red'; }
    elsif ( $pwr >= 35 && $pwr <= 35 ) { $color = 'yellow'; }
    elsif ( $pwr > 35 ) { $color = 'green'; }
    return colored($pwr, $color);
}

sub cpu {
    my $cpu = shift;
    my $color = 'green';
    if ($cpu > 0) { $color = 'yellow'; }
    if ($cpu > 1) { $color = 'red'; }
    return colored($cpu, $color);
}

my $regexp = crazy('(\d+) runts, (\d+) giants, (\d+) throttles',
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


sub interface {
    # without knowing syntax, this will automatically handle err-disable and
    # any other weird corner cases by defaulting to red.
    my $color = 'red';
    if ($_[0] eq 'up') {
        $color = 'green';
    }
    return colored($_[0], $color);
}


# this should start at the beginning statement (router bgp whatever..) and end
# at the closing statement (\n!).. BUT.. it needs to be able to continue
# through a second buffer if block_end isn't found..
sub process_block {
    my $self = shift;
    my $end = $self->{block_end};
    my $text = shift;
    if ($self->{block_begin}) {
        my $begin = $self->{block_begin};
        $text =~ s/($begin.*($end|$))/colored($1, $self->{block_color})/e;
        undef $self->{block_begin};
    } else {
        $text =~ s/(.*($end|$))/colored($1, $self->{block_color})/e;
    }

    if ($2 eq $self->{block_end}) {
        print "Block ended here..\n";
        undef $self->{block_end};
        undef $self->{block_color};
    }
}

sub colorize {
    my $self = shift;
    $_ = shift;

    # this doesn't work.  One reason is that two of these lines could be in
    # the same buffer and this would only catch it once (we would need to
    # split the buffer by \n to fix that)
    if (/\n(?:ipv6 )?router \S+/) {
        $self->{block_begin}=qr/\n(?:ipv6 )?router \S+/;
        $self->{block_end}=qr/\n!/;
        $self->{block_color}='cyan';
    } elsif (/\nip dhcp pool/) {
        $self->{block_begin}=qr/\nip dhcp pool/;
        $self->{block_end}=qr/\n!/;
        $self->{block_color}='cyan';
    } elsif (/\ninterface \S+/) {
        $self->{block_begin}=qr/\ninterface \S+/;
        $self->{block_end}=qr/\n!/;
        $self->{block_color}='bright_yellow';
    }

    s/(\S+) is (.*), line protocol is (\S+)/sprintf("%s is %s, line protocol is %s", colored($1, 'magenta'),
            interface($2), interface($3))/eg;

    # sh cable modem phy
    s#([a-f0-9\.]+ C\d+/\d+/U\d+\s+\d+\s+)([\d\.]+)(\s+)([\d\.]+)(\s+\!?\d+)([\s\-]+[\d\.]+)(\s+)([\d\.\-]+)#
        sprintf("%s%s%s%s%s%s%s%s", $1, uspwr($2), $3, ussnr($4), $5, dspwr($6), $7, dssnr($8))#eg;

    # more show interface
    s/Full-duplex/colored('Full-duplex', 'green')/eg;
    s/Half-duplex/colored('Half-duplex', 'yellow')/eg;

    # sh proc cpu
    s#(\s+\d+\s+\d+\s+\d+\s+\d+\s+)([\d\.]+)(%\s+)([\d\.]+)(%\s+)([\d\.]+)#sprintf("%s%s%s%s%s%s", $1, cpu($2), $3, cpu($4), $5, cpu($6))#eg;

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

    # the rest of show interface
    eval $regexp; ## no critic
    return $_;
}

1;
