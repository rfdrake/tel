use inc::Module::Install;

name           'App-Tel';
all_from       'lib/App/Tel.pm';
auto_provides;

requires       'Expect'  => '0.0';
requires       'IO::Stty'  => '0.0';
requires       'Time::HiRes';             # core
requires       'Getopt::Std';             # core
requires       'Getopt::Long';            # core
requires       'File::Temp';              # core
requires       'Cwd';                     # core
requires       'Scalar::Util';            # core

recommends     'Term::ANSIColor';         # core
recommends     'Term::ReadKey';
recommends     'Crypt::PWSafe3';
recommends     'File::KeePass';
recommends     'GnuPG::Interface';        # needed for App::Tel::Passwd::Pass
recommends     'IO::Handle';              # core
recommends     'IO::File';                # core
recommends     'Passwd::Keyring::Auto';
recommends     'NetAddr::IP';
recommends     'XML::Parser';             # required for File::KeePass, it's not listed as a dependency there
recommends     'Compress::Raw::Zlib';     # required for File::KeePass, it's not listed as a dependency there



install_script  'bin/tel';
install_script  'bin/mktelrc';

test_requires q(Test::Most) => 0.25;
test_requires q(Test::Fatal);
bugtracker q(https://github.com/rfdrake/tel/issues);
homepage q(http://search.cpan.org/dist/App-Tel);
repository q(git://github.com/rfdrake/tel.git);
license 'perl';

auto_install;
WriteAll;
