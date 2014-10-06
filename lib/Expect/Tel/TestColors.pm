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


package Expect::Tel::TestColors;
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
    s/(.*#)/sprintf("%s", colored($1, 'magenta'))/eg;
    return $_;
}

1;
