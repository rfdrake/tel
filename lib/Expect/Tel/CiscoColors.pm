#!/usr/bin/perl -w

# Copyright (C) 2007 Robert Drake
# This module is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
# This module is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.


# Notes:
# this code is very hard for me to read but it takes the output from "sh interface"
# and colors the numbers according to if they are zero or not.  Usually my
# perl isn't write-once-read-never, but I didn't come up with a good way of
# doing this and just made something work.
#
# This may be older than 2007.  I'm going by what git blame tells me. :)


package Expect::Tel::CiscoColors;
#use parent 'ColorObject';
use Term::ANSIColor;
use strict;

my $host_color = "magenta";
my $warn_color = "red";
my $good_color = "green";

$Term::ANSIColor::AUTORESET++;         # reset color after each print
$SIG{INT} = sub { print "\n"; exit; }; # reset color after Ctrl-C

sub c {
   my $value = shift;
   return $value if ($value =~ /\D/);
   if ($value > 0) {
      return colored($value, $warn_color);
   } else {
      return colored($value, $good_color);
   }
}

# not kidding, this will be crazy.
# it simulates s/blah (\d+) blah/sprintf("blah %s blah", c($1))/e;
sub crazy {
   my @strings = @_;
   my $evils;

   foreach my $s (@strings) {

      my $substring = $s;
      # (?<!\\)(?!\\) are funny things that mean look behind and look ahead
      # for \\ (the escape \ before a parenthesis)
      my $count = $substring =~ s/(?<!\\)(?!\\)\(.*?\)/%s/g;

      my $args;
      map { $args .= ",c(\$$_)"; } 1..$count;
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
    if ( $pwr < 35 ) { $color = 'red'; }
    if ( $pwr >= 35 && $pwr <= 35 ) { $color = 'yellow'; }
    if ( $pwr > 35 ) { $color = 'green'; }
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



sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return bless( {}, $class);
}

sub colorize {
    return colorizer($_[1]);
}

sub colorizer {

    $_ = shift;
    s/(\S+) is (.*), line protocol is (.*)/
       sprintf("%s is %s, line protocol is %s", colored($1, $host_color),
             colored($2, $2 ne "up" ? $warn_color : $good_color),
             colored($3, $2 ne "up" ? $warn_color : $good_color))/e;

    s#([a-f0-9\.]+ C\d+/\d+/U\d+\s+\d+\s+)([\d\.]+)(\s+)([\d\.]+)(\s+\!?\d+)([\s-]+[\d\.]+)(\s+)([\d\.]+)#
        sprintf("%s%s%s%s%s%s%s%s", $1, uspwr($2), $3, ussnr($4), $5, dspwr($6), $7, dssnr($8))#eg;

    s/Full-duplex/sprintf("%s", colored('Full-duplex', 'green'))/eg;
    s/Half-duplex/sprintf("%s", colored('Half-duplex', 'yellow'))/eg;

    s#(\s+\d+\s+\d+\s+\d+\s+\d+\s+)([\d\.]+)(%\s+)([\d\.]+)(%\s+)([\d\.]+)#sprintf("%s%s%s%s%s%s", $1, cpu($2), $3, cpu($4), $5, cpu($6))#eg;

    eval $regexp;
    return $_;
}

1;
