use strict;
use warnings;
use Test::More;

eval 'use File::KeePass; 1' or plan skip_all => 'Optional module File::KeePass required';

use App::Tel::Passwd::KeePass;
plan tests => 5;

my $test = App::Tel::Passwd::KeePass->new( 't/pass/keepass.kdbx', 'notsafe' );
is($test, undef, 'bad password returns undef?' );
$test = App::Tel::Passwd::KeePass->new( undef, 'notsafe' );
is($test, undef, 'unknown file returns undef?' );
$test = App::Tel::Passwd::KeePass->new( 't/pass/keepass.kdbx', 'verysafe' );
is(ref($test), 'App::Tel::Passwd::KeePass', 'Does new return object?');
is($test->passwd('router password'), 'hello', 'password correct?');
is($test->passwd('fake entry'), '', 'undefined entry returns blank string?');

