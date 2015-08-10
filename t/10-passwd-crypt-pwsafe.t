use strict;
use warnings;
use Test::More;

eval 'use Crypt::PWSafe3; 1' or plan skip_all => 'Optional module Crypt::PWSafe3 required';

use App::Tel::Passwd::PWSafe;
plan tests => 5;

my $test = App::Tel::Passwd::PWSafe->new( 't/pass/pwsafe.psafe3', 'notsafe' );
is($test, undef, 'bad password returns undef?' );
$test = App::Tel::Passwd::PWSafe->new( undef, 'notsafe' );
is($test, undef, 'unknown/non-existant file returns undef?' );
$test = App::Tel::Passwd::PWSafe->new( 't/pass/pwsafe.psafe3', 'verysafe' );
is(ref($test), 'App::Tel::Passwd::PWSafe', 'Does new return object?');
is($test->passwd('router password'), 'hello', 'password correct?');
is($test->passwd('fake entry'), '', 'undefined entry returns blank string?');

