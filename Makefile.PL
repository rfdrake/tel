use inc::Module::Install;

name           'App-Tel';
all_from       'lib/App/Tel.pm';

requires       'Hash::Merge::Simple'  => '0.0';
requires       'Expect'  => '0.0';
requires       'IO::Stty'  => '0.0';

recommends     'Term::ANSIColor';
recommends     'Term::ReadKey';
recommends     'File::KeePass';
recommends     'Passwd::Keyring::Auto';
recommends     'Time::HiRes';
recommends     'NetAddr::IP';

install_script  'bin/tel';
install_script  'bin/mktelrc';

test_requires q(Test::Most) => 0.31;
bugtracker q(https://github.com/rfdrake/tel/issues);
homepage q(http://search.cpan.org/dist/App-Tel);
repository q(git://github.com/rfdrake/tel.git);
license 'perl';

auto_install;
WriteAll;
