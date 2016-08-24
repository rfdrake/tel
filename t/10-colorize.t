use strict;
use warnings;
use Test::Most;
use Term::ANSIColor;
plan tests => 11;

use App::Tel::Color;

#use Data::Dumper;
#$Data::Dumper::Useqq =1;


subtest load_syntax => sub {
    my $colors = App::Tel::Color->new;

    warning_is { $colors->load_syntax('Test_Syntax_Failure', 0) } undef,
        'load_syntax will not warn on loading failure with debugging off';

    warning_like { $colors->load_syntax('Test_Syntax_Failure', 1) } qr#Can't locate App/Tel/Color/Test_Syntax_Failure.pm in \@INC#,
        'load_syntax gives warning on syntax loading failure (with debugging on)';

    $colors->load_syntax('Cisco', 1);
    my $t = $colors->colorize('0 packets input, 0 bytes, 0 no buffer');
    my $o = "0 packets input, 0 bytes, \e[32m0\e[0m no buffer";
    is($t, $o, 'Calling parser via Color.pm->colorize() works');

    $colors->{colors} = {};
    $colors->load_syntax(['CiscoLog','Cisco'], 1);
    is(scalar keys %{$colors->{colors}}, 2, 'Can we load two syntax by sending arrayref?');

    $colors->{colors} = {};
    $colors->load_syntax(['CiscoLog','Test_Syntax_Failure'], 0);
    is(scalar keys %{$colors->{colors}} , 1, 'valid + invalid should be 1?');

    $colors->{colors} = {};
    $colors->load_syntax(['Test_Syntax_Failure','Test_Syntax_Failure'], 0);
    is(scalar keys %{$colors->{colors}}, 0, 'invalid array = 0?');

    $colors->{colors} = {};
    $colors->load_syntax('Test_Syntax_Failure+Test_Syntax_Failure', 0);
    is(scalar keys %{$colors->{colors}}, 0, 'invalid + invalid = 0?');


    $colors->{colors} = {};
    $colors->load_syntax(undef, 1);
    is(scalar keys %{$colors->{colors}}, 0, 'handle undefined without errors');
    done_testing();
};

use App::Tel::Color::Base;
ok(scalar(@App::Tel::Color::Base::colors) > 0, 'available colors > zero?');

use App::Tel::Color::CiscoLog;

my $t = App::Tel::Color::CiscoLog->new->parse('Nov 22 21:59:54 EST: %SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)');
my $o = "Nov 22 21:59:54 EST: \e[31m%SYS-5-CONFIG_I: Configured from console by rdrake on vty0 (127.0.0.1)\e[0m";
is($t, $o, 'colorized output match?');

use App::Tel::Color::CiscoPingRainbow;
$t = App::Tel::Color::CiscoPingRainbow->new->parse('Sending 20, 100-byte ICMP Echos to 1.2.3.4, timeout is 2 seconds:
!!!!!!!!!!!!!....!!!
Success rate is 100 percent (20/20), round-trip min/avg/max = 1/1/4 ms');

if ($Term::ANSIColor::VERSION >= 3.00) {
    $o = "Sending 20, 100-byte ICMP Echos to 1.2.3.4, timeout is 2 seconds:\n\e[32;33;34;35;36;37;92;93;94;95;96;97m!\e[0m\e[33m!\e[0m\e[34m!\e[0m\e[35m!\e[0m\e[36m!\e[0m\e[37m!\e[0m\e[92m!\e[0m\e[93m!\e[0m\e[94m!\e[0m\e[95m!\e[0m\e[96m!\e[0m\e[97m!\e[0m\e[32;33;34;35;36;37;92;93;94;95;96;97m!\e[0m\e[31m.\e[0m\e[31m.\e[0m\e[31m.\e[0m\e[31m.\e[0m\e[33m!\e[0m\e[34m!\e[0m\e[35m!\e[0m\nSuccess rate is 100 percent (20/20), round-trip min/avg/max = 1/1/4 ms";
} else {
    $o = "Sending 20, 100-byte ICMP Echos to 1.2.3.4, timeout is 2 seconds:\n\e[32;33;34;35;36;37m!\e[0m\e[33m!\e[0m\e[34m!\e[0m\e[35m!\e[0m\e[36m!\e[0m\e[37m!\e[0m\e[32;33;34;35;36;37m!\e[0m\e[33m!\e[0m\e[34m!\e[0m\e[35m!\e[0m\e[36m!\e[0m\e[37m!\e[0m\e[32;33;34;35;36;37m!\e[0m\e[31m.\e[0m\e[31m.\e[0m\e[31m.\e[0m\e[31m.\e[0m\e[33m!\e[0m\e[34m!\e[0m\e[35m!\e[0m\nSuccess rate is 100 percent (20/20), round-trip min/avg/max = 1/1/4 ms";
}
is($t, $o, 'pingrainbow output match?');

use App::Tel::Color::Cisco;
my $cisco = App::Tel::Color::Cisco->new;

# color interface
$t = $cisco->parse('0 output errors, 0 collisions, 1 interface resets');
$o = "\e[32m0\e[0m output errors, \e[32m0\e[0m collisions, \e[31m1\e[0m interface resets";
is($t, $o, 'cisco color interface match');

# sh cable modem phy
my $scm = <<'SCM';
e86d.526f.424d C1/0/U0       1     35.25  19.01 2407  -15.20  -----  atdma* 1.1
e86d.526f.424d C1/0/U1       1     32.25  28.51 2379  -10.00  33.90  atdma* 1.1
e86d.526f.424d C1/0/U2       1     46.25  23.00 2379    6.00  35.00  atdma* 1.1
e86d.526f.424d C1/0/U3       1     55.25  30.79 2380   10.20  37.90  atdma* 1.1
e86d.526f.424d C1/0/U3       1     55.25  30.79 2380   19.20  37.90  atdma* 1.1
e86d.526f.424d C1/0/U3       1     55.25  30.79 !2380  19.20  37.90  atdma* 1.1
SCM

$t = $cisco->parse($scm);
$o = "e86d.526f.424d C1/0/U0       1     \e[32m35.25\e[0m  \e[31m19.01\e[0m 2407\e[31m  -15.20\e[0m\e[33m  -----\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U1       1     \e[33m32.25\e[0m  \e[32m28.51\e[0m 2379\e[33m  -10.00\e[0m\e[31m  33.90\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U2       1     \e[33m46.25\e[0m  \e[33m23.00\e[0m 2379\e[32m    6.00\e[0m\e[33m  35.00\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U3       1     \e[31m55.25\e[0m  \e[32m30.79\e[0m 2380\e[33m   10.20\e[0m\e[32m  37.90\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U3       1     \e[31m55.25\e[0m  \e[32m30.79\e[0m 2380\e[31m   19.20\e[0m\e[32m  37.90\e[0m  atdma* 1.1\ne86d.526f.424d C1/0/U3       1     \e[31m55.25\e[0m  \e[32m30.79\e[0m !2380\e[31m  19.20\e[0m\e[32m  37.90\e[0m  atdma* 1.1\n";
is($t, $o, 'cisco scm phy color match');

# sh proc cpu
$t = $cisco->parse('   6    80639888   5519824 14609 0.00%  0.34%  1.25%   0 Check heaps');
$o = "   6    80639888   5519824 14609 \e[32m0.00\e[0m%  \e[33m0.34\e[0m%  \e[31m1.25\e[0m%   0 Check heaps";
is($t, $o, 'sh proc cpu');

# 4500x sh proc cpu
$t = $cisco->parse('1       1019        870       1171 0.00 0.00 0.00 0     init
127.0.0.1       4 65182  677835  677867     1317    0    0 1w6d            2');
$o = "1       1019        870       1171 \e[32m0.00\e[0m \e[32m0.00\e[0m \e[32m0.00\e[0m 0     init\n127.0.0.1       4 65182  677835  677867     1317    0    0 1w6d            2";
is($t, $o, '4500x sh proc cpu');

$t = $cisco->parse('Vlan55 is up, line protocol is down');
$o = "\e[35mVlan55\e[0m is \e[32mup\e[0m, line protocol is \e[31mdown\e[0m";
is($t, $o, 'Interface name coloring works');

# this one is special because _c needs to return the "no buffer" text without
# modification
$t = $cisco->parse('0 packets input, 0 bytes, 0 no buffer');
$o = "0 packets input, 0 bytes, \e[32m0\e[0m no buffer";
is($t, $o, 'Interface buffer match works');

subtest false_positives => sub {
    my ($t, $raw);

    # sh diag on CMTS getting colored
    $raw = '
          0x00: 04 FF 40 06 75 C1 8B 43 41 54 31 39 33 30 45 31
          0x30: 33 20 C6 8A 49 50 55 43 41 59 30 42 41 42 88 00
          0x40: 00 00 00 02 02 03 00 81 00 00 00 00 04 00 8B 00
          0x80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00';
    $t = $cisco->parse($raw);
    is($t,$raw,'Is sh diag mangled by colors?');


    # show c7200 getting colored:
    $raw = '
          0x00: 04 FF 40 01 76 01 06 41 01 05 C0 46 03 20 00 15
          0x10: 43 03 42 41 30 80 00 00 00 00 02 03 C1 8B 53 44
          0x20: 41 30 36 30 35 30 30 36 33 C2 8B 53 43 41 30 36
          0x40: 00 03 00 81 00 00 00 00 04 00 C7 20 01 00 02 BE
          0x20: 04 42 45 30 C1 8B 4A 41 46 31 35 33 37 42 50 4A';

    $t = $cisco->parse($raw);
    is($t,$raw,'Is sh c7200 mangled by colors?');
};
