use strict;
use warnings;
use Test::Most;
plan tests => 14;

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

# color interface
$t = App::Tel::Color::Cisco->new->colorize('0 output errors, 0 collisions, 1 interface resets');
$o = "\e[32m0\e[0m output errors, \e[32m0\e[0m collisions, \e[31m1\e[0m interface resets";
is($t, $o, 'cisco color interface match');

# sh cable modem phy
my $scm = <<'SCM';
e86d.526f.424d C1/0/U0       1     35.25  19.01 2407  -15.20  -----  atdma* 1.1
e86d.526f.424d C1/0/U1       1     32.25  28.51 2379  -10.00  33.90  atdma* 1.1
e86d.526f.424d C1/0/U2       1     46.25  23.00 2379    6.00  35.00  atdma* 1.1
e86d.526f.424d C1/0/U3       1     55.25  30.79 2380   10.20  37.90  atdma* 1.1
e86d.526f.424d C1/0/U3       1     55.25  30.79 2380   19.20  37.90  atdma* 1.1
SCM

$t = App::Tel::Color::Cisco->new->colorize($scm);
$o = "e86d.526f.424d C1/0/U0       1     \e[32m35.25\e[0m  \e[31m19.01\e[0m 2407\e[31m  -15.20\e[0m  \e[33m-----\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U1       1     \e[33m32.25\e[0m  \e[32m28.51\e[0m 2379\e[33m  -10.00\e[0m  \e[31m33.90\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U2       1     \e[33m46.25\e[0m  \e[33m23.00\e[0m 2379\e[32m    6.00\e[0m  \e[33m35.00\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U3       1     \e[31m55.25\e[0m  \e[32m30.79\e[0m 2380\e[33m   10.20\e[0m  \e[32m37.90\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U3       1     \e[31m55.25\e[0m  \e[32m30.79\e[0m 2380\e[31m   19.20\e[0m  \e[32m37.90\e[0m  atdma* 1.1\n";
is($t, $o, 'cisco scm phy color match');

# sh proc cpu
$t = App::Tel::Color::Cisco->new->colorize('   6    80639888   5519824 14609 0.00%  0.34%  1.25%   0 Check heaps');
$o = "   6    80639888   5519824 14609 \e[32m0.00\e[0m%  \e[33m0.34\e[0m%  \e[31m1.25\e[0m%   0 Check heaps";
is($t, $o, 'sh proc cpu');


$t = App::Tel::Color::Cisco->new->colorize('Vlan55 is up, line protocol is down');
$o = "\e[35mVlan55\e[0m is \e[32mup\e[0m, line protocol is \e[31mdown\e[0m";
is($t, $o, 'Interface name coloring works');

# this one is special because _c needs to return the "no buffer" text without
# modification
$t = App::Tel::Color::Cisco->new->colorize('0 packets input, 0 bytes, 0 no buffer');
$o = "0 packets input, 0 bytes, \e[32m0\e[0m no buffer";
is($t, $o, 'Interface buffer match works');

is(scalar @{load_syntax(['CiscoLog','Cisco'], 1)}, 2, 'Can we load two syntax by sending arrayref?');

is(scalar @{load_syntax(['CiscoLog','Test_Syntax_Failure'], 0)}, 1, 'valid + invalid should be 1?');

is(scalar @{load_syntax(['Test_Syntax_Failure','Test_Syntax_Failure'], 0)}, 0, 'invalid array = 0?');
is(scalar @{load_syntax('Test_Syntax_Failure+Test_Syntax_Failure', 0)}, 0, 'invalid + invalid = 0?');
is(scalar @{load_syntax(undef, 1)}, 0, 'handle undefined without errors');

