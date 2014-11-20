use strict;
use warnings;
use Test::More;

require 'bin/tel';

# 1. try new
my $test = App::Tel->new();

ok(ref($test) eq 'App::Tel', 'App::Tel->new() should return a App::Tel object.');

done_testing();
