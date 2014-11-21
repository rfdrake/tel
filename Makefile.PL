use inc::Module::Install;

name           'App-Tel';
all_from       'bin/tel';

requires       'Hash::Merge::Simple'  => '0.0';
requires       'Expect'  => '0.0';

recommends     'Term::ANSIColor';
recommends     'File::KeePass';
recommends     'Passwd::Keyring::Auto';

install_script  'bin/tel';
install_script  'bin/mktelrc';

test_requires q(Test::Most) => 0.33;
bugtracker q(https://github.com/rfdrake/tel/issues);
homepage q(http://search.cpan.org/dist/App-Tel);
repository q(git://github.com/rfdrake/tel.git);
license 'perl';

auto_install;
WriteAll;
