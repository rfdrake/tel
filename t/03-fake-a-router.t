use strict;
use warnings;
use Test::More;
plan tests => 2;
use App::Tel;

use Config;
my $path_to_perl = $Config{perlpath};

my $tel = App::Tel->new();
$tel->load_config('t/rc/fakerouter.rc');

# loading the default profile to pickup the vty password
$tel->profile('default', 1);

# suppress as much output as we can because it interferes with testing
$tel->{log_stdout}=0;
# using this to load the rtr config so we turn on the exec method
$tel->rtr_find("t/fake_routers/loopback");
$tel->login("$path_to_perl t/fake_routers/loopback");
# add newlines to try to make sure "ok 1" is printed on it's own line.
#  instead of this, we're just going to have to make the fake router \n after
#  password lines so the errors don't happen
print "\n";
is($tel->connected, 1, 'Did we make it through login?');
is($tel->enable->enabled, 1, 'Did we enable successfully?');

$tel->send("sh ver\r");
$tel->expect('#');
$tel->send("exit\r");
$tel->disconnect;    # soft close
$tel->disconnect(1); # hard close

