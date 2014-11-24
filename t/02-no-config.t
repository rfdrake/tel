use strict;
use warnings;
use Test::Most;
use App::Tel;

plan tests => 1;

my $tel = App::Tel->new();
warning_is { $tel->load_config("/a/path/unlik.ely/_to/exist") } "No configuration files loaded. You may need to run mktelrc.",
    'load_config gives warning on no config loaded';

