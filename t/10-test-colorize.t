use strict;
use warnings;
use Test::More;
plan tests => 5;

use App::Tel::ColorObject;
ok(scalar(@App::Tel::ColorObject::colors) > 0, 'available colors > zero?');

use App::Tel::CiscoLogColors;

my $t = App::Tel::CiscoLogColors->new->colorize('Nov 22 21:59:54 EST: %SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)');
my $o = "Nov 22 21:59:54 EST: \e[31m%SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)\e[0m";
is($t, $o, 'colorized output match?');


use App::Tel::CiscoColors;

$t = App::Tel::CiscoColors->new->colorize('0 output errors, 0 collisions, 1 interface resets');
$o = "\e[32m0\e[0m output errors, \e[32m0\e[0m collisions, \e[31m1\e[0m interface resets";
is($t, $o, 'cisco color interface match');

$t = App::Tel::CiscoColors->new->colorize('0000.0000.0000 C1/0/U0 1 40.70  36.12 2117  - 2.80  41.40  atdma  1.0');
$o = "0000.0000.0000 C1/0/U0 1 \e[32m40.70\e[0m  \e[32m36.12\e[0m 2117\e[32m  - 2.80\e[0m  \e[32m41.40\e[0m  atdma  1.0";
is($t, $o, 'cisco scm phy color match');

$t = App::Tel::CiscoColors->new->colorize('Vlan55 is down, line protocol is down');
$o = "\e[35mVlan55\e[0m is \e[31mdown\e[0m, line protocol is \e[31mdown\e[0m";
is($t, $o, 'Interface name coloring works');

