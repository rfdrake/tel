use strict;
use warnings;
use Test::Most;

plan tests => 1;

require 'bin/tel';

my $tel = Expect::Tel->new();
warning_is { Expect::Tel->load_config("/a/path/unlik.ely/_to/exist") } "No configuration files loaded. You may need to run mktelrc.",
    'load_config gives warning on no config loaded';



