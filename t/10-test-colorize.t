use strict;
use warnings;
use Test::Most;
plan tests => 8;

use App::Tel::Color qw ( load_syntax );

warning_is { load_syntax('Test_Syntax_Failure', 0) } undef,
    'load_syntax will not warn on loading failure with debugging off';

warning_like { load_syntax('Test_Syntax_Failure', 1) } qr#Can't locate App/Tel/Color/Test_Syntax_Failure.pm in \@INC#,
    'load_syntax gives warning on syntax loading failure (with debugging on)';

use App::Tel::Color::Base;
ok(scalar(@App::Tel::Color::Base::colors) > 0, 'available colors > zero?');

use App::Tel::Color::CiscoLog;

my $t = App::Tel::Color::CiscoLog->new->colorize('Nov 22 21:59:54 EST: %SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)');
my $o = "Nov 22 21:59:54 EST: \e[31m%SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)\e[0m";
is($t, $o, 'colorized output match?');


use App::Tel::Color::Cisco;

$t = App::Tel::Color::Cisco->new->colorize('0 output errors, 0 collisions, 1 interface resets');
$o = "\e[32m0\e[0m output errors, \e[32m0\e[0m collisions, \e[31m1\e[0m interface resets";
is($t, $o, 'cisco color interface match');

$t = App::Tel::Color::Cisco->new->colorize('0000.0000.0000 C1/0/U0 1 40.70  36.12 2117  - 2.80  41.40  atdma  1.0');
$o = "0000.0000.0000 C1/0/U0 1 \e[32m40.70\e[0m  \e[32m36.12\e[0m 2117\e[32m  - 2.80\e[0m  \e[32m41.40\e[0m  atdma  1.0";
is($t, $o, 'cisco scm phy color match');

$t = App::Tel::Color::Cisco->new->colorize('Vlan55 is down, line protocol is down');
$o = "\e[35mVlan55\e[0m is \e[31mdown\e[0m, line protocol is \e[31mdown\e[0m";
is($t, $o, 'Interface name coloring works');

# this one is special because _c needs to return the "no buffer" text without
# modification
$t = App::Tel::Color::Cisco->new->colorize('0 packets input, 0 bytes, 0 no buffer');
$o = "0 packets input, 0 bytes, \e[32m0\e[0m no buffer";
is($t, $o, 'Interface buffer match works');

