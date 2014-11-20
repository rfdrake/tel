use strict;
use warnings;
use Test::More;

require 'bin/tel';

my $tel = Expect::Tel->new();
$tel->profile('default', 1);

my $hostname = $tel->hostname("router:8080");
is($tel->{port}, 8080, "port set to 8080");
is($tel->{methods}->[0], 'telnet', 'Method set to telnet');
is($hostname, 'router', 'hostname = router');

$hostname = $tel->hostname("fe80::1");
is($hostname, 'fe80::1', 'raw IPv6 address works');

$hostname = $tel->hostname("[fe80::1]:8080");
is($tel->{port}, 8080, "port set to 8080");
is($tel->{methods}->[0], 'telnet', 'Method set to telnet');
is($hostname, 'fe80::1', 'bracketed hostname with port works');

$hostname = $tel->hostname("[fe80::1]");
is($hostname, 'fe80::1', 'bracketed hostname without port works');

$hostname = $tel->hostname("ssh://[fe80::1]:8080");
is($tel->{port}, 8080, "port set to 8080");
is($tel->{methods}->[0], 'ssh', 'Method set to ssh');
is($hostname, 'fe80::1', 'uri with bracketed hostname and port works');

$hostname = $tel->hostname("ssh://[fe80::1]");
is($tel->{methods}->[0], 'ssh', 'Method set to ssh');
is($hostname, 'fe80::1', 'uri with bracketed hostname (no port) works');

$hostname = $tel->hostname("ssh://router:8080");
is($tel->{port}, 8080, "port set to 8080");
is($tel->{methods}->[0], 'ssh', 'Method set to ssh');
is($hostname, 'router', 'uri with unbracketed hostname and port works');

$hostname = $tel->hostname("ssh://router");
is($tel->{methods}->[0], 'ssh', 'Method set to ssh');
is($hostname, 'router', 'uri with unbracketed hostname works');

$hostname = $tel->hostname("router");
is($hostname, 'router', 'regular non-weird hostname works');


done_testing();


