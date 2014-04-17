use strict;
use warnings;
use Test::More;

require 'tel';

# 1. try new
my $test = Local::Tel->new();

ok(ref($test) eq 'Local::Tel', 'Local::Tel->new() should return a Local::Tel object.');

done_testing();
