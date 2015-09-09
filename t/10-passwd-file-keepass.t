use strict;
use warnings;
use Test::More;
use Test::Exception;
eval 'use File::KeePass; 1' or plan skip_all => 'Optional module File::KeePass required';
plan tests => 6;

my $mod = 'KeePass';
my $good_file = 't/pass/keepass.kdbx';

use App::Tel::Passwd;
lives_ok { App::Tel::Passwd::load_module($mod, $good_file, 'verysafe' ) } "load_module on $mod works";

use App::Tel::Passwd::KeePass;

dies_ok { App::Tel::Passwd::KeePass->new( file => undef, passwd => 'notsafe' ) } 'Bad file croaks';
dies_ok { App::Tel::Passwd::KeePass->new( file => $good_file, passwd => 'notsafe' ) } 'Bad password croaks';

my $test = App::Tel::Passwd::KeePass->new( file => $good_file, passwd => 'verysafe' );
is(ref($test), 'App::Tel::Passwd::KeePass', 'Does new return object?');
is($test->passwd('router password'), 'hello', 'password correct?');
is($test->passwd('fake entry'), '', 'undefined entry returns blank string?');

