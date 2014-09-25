use inc::Module::Install;

name           'Expect-Tel';
all_from       'bin/tel';

requires       'Hash::Merge::Simple'  => '0.0';
requires       'Expect'  => '0.0';

install_script  'bin/tel';
install_script  'bin/mktelrc';

test_requires q(Test::More) => 0.90;
repository q(git://github.com/rfdrake/tel.git);
license 'perl';

auto_install;
WriteAll;
