use strict;
use warnings;
use Test::More;
use App::Tel;

my $tel = App::Tel->new();

is_deeply($tel->methods, [ 'ssh', 'telnet' ], 'Are we using the default methods?');

$tel->methods('set_method');
is_deeply($tel->methods, [ 'set_method' ], 'Can we override the existing method?');

$tel->{opts}->{m} = qw ( cli_method );
$tel->{methods}=();
is_deeply($tel->methods, [ 'cli_method' ], 'Can we override the existing method on the CLI?');


done_testing();


