use strict;
use warnings;
use Test::More;
use Test::Exception;
eval 'use Crypt::PWSafe3; 1' or plan skip_all => 'Optional module Crypt::PWSafe3 required';
plan tests => 6;

my $mod = 'PWSafe';
my $good_file = 't/pass/pwsafe.psafe3';

use App::Tel::Passwd;
lives_ok { App::Tel::Passwd::load_module($mod, $good_file, 'verysafe' ) } "load_module on $mod works";

use App::Tel::Passwd::PWSafe;

dies_ok { App::Tel::Passwd::PWSafe->new( file => undef, passwd => 'notsafe' ) } 'Bad file croaks';
dies_ok { App::Tel::Passwd::PWSafe->new( file => $good_file, passwd => 'notsafe' ) } 'Bad password croaks';
my $test = App::Tel::Passwd::PWSafe->new( file => $good_file, passwd => 'verysafe' );
is(ref($test), "App::Tel::Passwd::PWSafe", 'Does new return object?');
is($test->passwd('router password'), 'hello', 'password correct?');
is($test->passwd('fake entry'), '', 'undefined entry returns blank string?');

