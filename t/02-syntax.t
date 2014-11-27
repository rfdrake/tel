use strict;
use warnings;
use Test::Most;
use App::Tel;

plan tests => 3;

my $tel = App::Tel->new();

is ($tel->{opts}->{d}, undef, 'is the debug flag set to off (undef)');

warning_is { $tel->load_syntax('Test_Syntax_Failure') } undef,
    'load_syntax will not warn on loading failure with debugging off';

$tel->{opts}->{d}=1;  # set the debug option

warning_like { $tel->load_syntax('Test_Syntax_Failure') } qr/Can't locate App\/Tel\/Test_Syntax_FailureColors\.pm in \@INC/,
    'load_syntax gives warning on syntax loading failure (with debugging on)';

