use strict;
use warnings;
use Test::Most;

plan tests => 1;

require 'bin/tel';

my $tel = App::Tel->new();
warning_is { App::Tel->load_config("/a/path/unlik.ely/_to/exist") } "No configuration files loaded. You may need to run mktelrc.",
    'load_config gives warning on no config loaded';



