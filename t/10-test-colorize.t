use strict;
use warnings;
use Test::More;

use App::Tel::CiscoLogColors;
plan tests => 4;

my $test = new App::Tel::CiscoLogColors;
my $output = $test->colorize('Nov 22 21:59:54 EST: %SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)');

is($output, "Nov 22 21:59:54 EST: \e[31m%SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)\e[0m", 'colorized output match?');

use App::Tel::ColorObject;
ok(scalar(@App::Tel::ColorObject::colors) > 0, 'available colors > zero?');

use App::Tel::CiscoColors;

my $cisco_interface = App::Tel::CiscoColors->new->colorize('0 output errors, 0 collisions, 1 interface resets');
is($cisco_interface, "\e[32m0\e[0m output errors, \e[32m0\e[0m collisions, \e[31m1\e[0m interface resets", 'cisco color interface match');

my $cisco_phy = App::Tel::CiscoColors->new->colorize('0000.0000.0000 C1/0/U0 1 40.70  36.12 2117  - 2.80  41.40  atdma  1.0');

is($cisco_phy, "0000.0000.0000 C1/0/U0 1 \e[32m40.70\e[0m  \e[32m36.12\e[0m 2117\e[32m  - 2.80\e[0m  \e[32m41.40\e[0m  atdma  1.0", 'cisco scm phy color match');
