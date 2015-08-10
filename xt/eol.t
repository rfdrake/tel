use Test::More;
eval 'use Test::EOL; 1' or plan skip_all => 'Test::EOL required';
all_perl_files_ok({ trailing_whitespace => 1 });
