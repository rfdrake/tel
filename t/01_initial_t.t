use strict;
use warnings;
use Test::More;

require 'tel';

# 1. try new
my $test = Expect::Tel->new();

ok(ref($test) eq 'Expect::Tel', 'Expect::Tel->new() should return a Expect::Tel object.');

done_testing();
