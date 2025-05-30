use Test::More;
use Test::EOL;
all_perl_files_ok({ trailing_whitespace => 1 }, 'lib','bin');
