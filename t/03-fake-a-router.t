use strict;
use warnings;
our $telrc;
require 't/dottelrc.testing';
use Test::More;
plan tests => 2;
use App::Tel;

use Config;
my $path_to_perl = $Config{perlpath};

# need to test
# rtr->hostname as CODE and as an alias
# method changes with split
# hostname:port options
# ssh options changes
# no banner and banners


my $tel = App::Tel->new();
$tel->{config} = $telrc;

# loading the default profile to pickup the vty password
$tel->profile('default', 1);

# using this to load the rtr config so we turn on the exec method
$tel->rtr_find("t/fake_routers/loopback");
$tel->login("$path_to_perl t/fake_routers/loopback");
# suppress as much output as we can because it interferes with testing
#$tel->session->log_stdout(0);
# add newlines to try to make sure "ok 1" is printed on it's own line.
#  instead of this, we're just going to have to make the fake router \n after
#  password lines so the errors don't happen
is($tel->connected, 1, 'Did we make it through login?');
is($tel->enable, 1, 'Did we enable successfully?');

$tel->send("sh ver\r");
$tel->expect('#');
$tel->send("exit\r");
$tel->disconnect;


