#!perl

use Test::More 0.96;
use Test::Vars;

subtest 'unused vars' => sub {
    all_vars_ok();
};

done_testing();
