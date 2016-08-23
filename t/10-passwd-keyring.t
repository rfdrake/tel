use strict;
use warnings;
use Test::More;
use Test::Exception;
eval 'use Passwd::Keyring::Auto; 1' ## no critic qw(BuiltinFunctions::ProhibitStringyEval)
    or plan skip_all => 'Optional module Passwd::Keyring::Auto required';

$ENV{PASSWD_KEYRING_FORCE}='Memory'; # requires 0.70 or greater of P::K::Auto


use App::Tel::Passwd qw ( keyring );

$App::Tel::Passwd::appname = 'tel script test interface';
$App::Tel::Passwd::test_password = 'test123';

is(keyring('test','test','test'), 'test123', 'Does keyring() return the password we set');

# this line does nothing but ensure we're reading the password from
# Passwd::Keyring::Auto.  If we are still reading from input_password then
# the next tests will fail.
$App::Tel::Passwd::test_password = 'testing 2';

is(keyring('test','test','test'), 'test123', 'Does keyring return the original password');

use App::Tel::Passwd::Mock;
# because we use a different group for KEYRING ('mock' instead of 'test') the
# keyring password is now 'testing 2'
$App::Tel::Passwd::Mock::initial_pw = 'testing 2';

my $e = App::Tel::Passwd::load_from_profile({ mock_passwd => 'KEYRING', mock_file => '/dev/null' });
is($e,'mock password', 'password correct if load_from_profile used with KEYRING?');

done_testing();
