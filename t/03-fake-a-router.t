use strict;
use warnings;
use Test::More;

require 'bin/tel';
our $telrc;
require 't/dottelrc.testing';

# need to test
# rtr->hostname as CODE and as an alias
# method changes with split
# hostname:port options
# ssh options changes


my $tel = Expect::Tel->new();
$tel->{config} = $telrc;

#using this to load the profile so we turn on the exec method
$tel->rtr_find("t/fake_routers/loopback");

$tel->login("t/fake_routers/loopback");
is($tel->connected, 1, 'Did we make it through login?');
$tel->enable();

$tel->send("sh ver\r");
$tel->conn();

done_testing();


