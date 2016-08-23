use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cwd qw ( abs_path );
eval 'use GnuPG::Interface; 1' ## no critic qw(BuiltinFunctions::ProhibitStringyEval)
    or plan skip_all => 'Optional module GnuPG::Interface required';

plan tests => 8;

my $mod = 'Pass';
my $good_file = 't/pass/Pass.gpg';


# for testing we need to use abs_path because the files aren't under the
# $HOME/.password-store directory.

use App::Tel::Passwd;
lives_ok { App::Tel::Passwd::load_module($mod, abs_path($good_file), 'verysafe' ) } "load_module on $mod works";

my $profile = {
    'pass_file' => abs_path($good_file),
    'pass_passwd' => 'verysafe'
};

my $e = App::Tel::Passwd::load_from_profile($profile);
is($e,'hello', 'password correct if load_from_profile used without _entry?');

use App::Tel::Passwd::Pass;

dies_ok { App::Tel::Passwd::Pass->new( file => undef, passwd => 'notsafe' ) } 'Bad file croaks';
dies_ok { App::Tel::Passwd::Pass->new( file => abs_path($good_file), passwd => 'notsafe' ) } 'Bad password croaks';

lives_ok {  App::Tel::Passwd::Pass->new( file => abs_path($good_file), passwd => 'verysafe' ) } "Loading with full path works.";
lives_ok {  App::Tel::Passwd::Pass->new( file => abs_path('t/pass/Pass'), passwd => 'verysafe' ) } "Loading with full path without extension works.";

my $test = App::Tel::Passwd::Pass->new( file => abs_path($good_file), passwd => 'verysafe' );
is(ref($test), 'App::Tel::Passwd::Pass', 'Does new return object?');
is($test->passwd('router password'), 'hello', 'password correct?');
