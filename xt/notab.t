#!perl
use Test::More;
eval 'use Test::NoTabs; 1' or plan skip_all => 'Test::NoTabs required';
all_perl_files_ok();
