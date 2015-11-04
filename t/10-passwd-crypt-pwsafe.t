use strict;
use warnings;
use Test::Stream -V1;
eval 'use Crypt::PWSafe3; 1' or plan skip_all => 'Optional module Crypt::PWSafe3 required';

my $mod = 'PWSafe';
my $good_file = 't/pass/pwsafe.psafe3';

use App::Tel::Passwd;

# if this fails/dies then we get an error so we shouldn't need lives_ok
is(ref(App::Tel::Passwd::load_module($mod, $good_file, 'verysafe' )),
    'App::Tel::Passwd::PWSafe', "load_module on $mod works");

use App::Tel::Passwd::PWSafe;

like( dies { App::Tel::Passwd::PWSafe->new( file => undef, passwd => 'notsafe' ) },
        qr/Can't read file <undefined>/, 'Bad file croaks');
like( dies { App::Tel::Passwd::PWSafe->new( file => $good_file, passwd => 'notsafe' ) },
        qr/Wrong password!/, 'Bad password croaks');

my $test = App::Tel::Passwd::PWSafe->new( file => $good_file, passwd => 'verysafe' );
is(ref($test), "App::Tel::Passwd::PWSafe", 'Does new return object?');
is($test->passwd('router password'), 'hello', 'password correct?');
is($test->passwd('fake entry'), '', 'undefined entry returns blank string?');
done_testing();
