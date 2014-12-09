use strict;
use warnings;
use Test::More;

use App::Tel::CiscoLogColors;
plan tests => 2;

my $test = new App::Tel::CiscoLogColors;
my $output = $test->colorize('Nov 22 21:59:54 EST: %SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)');

is($output, "Nov 22 21:59:54 EST: \e[31m%SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)\e[0m", 'colorized output match?');

use App::Tel::ColorObject;
ok(scalar(@App::Tel::ColorObject::colors) > 0, 'available colors > zero?');
