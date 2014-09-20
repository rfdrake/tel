use strict;
use warnings;
use Test::More;

require 'tel';
our $telrc;
require 't/dottelrc.testing';

# need to test
# rtr->hostname as CODE and as an alias
# method changes with split
# hostname:port options
# ssh options changes


my $tel = Expect::Tel->new();
ok(ref($tel) eq 'Expect::Tel', 'Expect::Tel->new() should return a Expect::Tel object.');
$tel->{config} = $telrc;

$tel->login("loopback");
is($tel->connected, 1, 'Did we make it through login?');
$tel->enable();

$tel->send("sh ver\r");
$tel->conn();

done_testing();


