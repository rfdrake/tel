use strict;
use warnings;
use Test::More;

require 'tel';

# 1. try new
my $tel = Expect::Tel->new();
my $config = Expect::Tel->load_config("dottelrc.sample");


ok(ref($tel) eq 'Expect::Tel', 'Expect::Tel->new() should return a Expect::Tel object.');

done_testing();


