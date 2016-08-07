use strict;
use warnings;
use Test::More;
use App::Tel;

# 1. try new
my $tel = App::Tel->new();
$tel->load_config("dottelrc.sample");

ok(ref($tel) eq 'App::Tel', 'App::Tel->new() should return a App::Tel object.');

done_testing();


