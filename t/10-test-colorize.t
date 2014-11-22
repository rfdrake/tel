use strict;
use warnings;
use Test::More;

use App::Tel::CiscoPingRainbowColors;

plan tests => 1;

my $test = new App::Tel::CiscoPingRainbowColors;
my $output = $test->colorize('Sending 10, 100-byte ICMP Echos to 10.0.0.1, timeout is 2 seconds:
!!!!!!!!!!
Success rate is 100 percent (10/10), round-trip min/avg/max = 1/1/4 ms');

is($output, "Sending 10, 100-byte ICMP Echos to 10\e[31m.\e[0m0\e[31m.\e[0m0\e[31m.\e[0m1, timeout is 2 seconds:\n\e[32m!\e[0m\e[33m!\e[0m\e[34m!\e[0m\e[35m!\e[0m\e[36m!\e[0m\e[37m!\e[0m\e[92m!\e[0m\e[93m!\e[0m\e[94m!\e[0m\e[95m!\e[0m\nSuccess rate is 100 percent (10/10), round-trip min/avg/max = 1/1/4 ms");
