use strict;
use warnings;
require 'bin/tel';
our $telrc;
require 't/dottelrc.testing';
use Test::More;
plan tests => 2;


# need to test
# rtr->hostname as CODE and as an alias
# method changes with split
# hostname:port options
# ssh options changes
# no banner and banners


my $tel = Expect::Tel->new();
$tel->{config} = $telrc;


#using this to load the profile so we turn on the exec method
$tel->rtr_find("t/fake_routers/loopback");
$tel->login("t/fake_routers/loopback");
# suppress as much output as we can because it interferes with testing
$tel->session->log_stdout(0);
# add newlines to try to make sure "ok 1" is printed on it's own line.
print "\n";
is($tel->connected, 1, 'Did we make it through login?');
print "\n";
is($tel->enable, 1, 'Did we enable successfully?');

$tel->send("sh ver\r");
$tel->expect("#");
$tel->send("exit\r");
$tel->disconnect;


