#!perl

use Test::More 0.96;
eval 'require Test::Vars; 1' or plan skip_all => "Test::Vars required for testing for unused vars";

Test::Vars->import;

subtest 'unused vars' => sub {
    all_vars_ok();
};

done_testing();
