use inc::Module::Install;

name           'App-Tel';
all_from       'lib/App/Tel.pm';

requires       'Hash::Merge::Simple'  => '0.0';
requires       'Expect'  => '0.0';
requires       'IO::Stty'  => '0.0';
requires       'Time::HiRes';             # core

recommends     'Term::ANSIColor';         # core
recommends     'Term::ReadKey';
recommends     'Crypt::PWSafe3';
recommends     'Passwd::Keyring::Auto';
recommends     'NetAddr::IP';
recommends     'File::KeePass';
recommends     'XML::Parser';             # required for File::KeePass, it's not listed as a dependency there
recommends     'Compress::Raw::Zlib';     # required for File::KeePass, it's not listed as a dependency there


install_script  'bin/tel';
install_script  'bin/mktelrc';

test_requires q(Test::Most) => 0.25;
bugtracker q(https://github.com/rfdrake/tel/issues);
homepage q(http://search.cpan.org/dist/App-Tel);
repository q(git://github.com/rfdrake/tel.git);
license 'perl';

auto_install;
WriteAll;
