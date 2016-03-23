requires       'Expect'  => '0.0';
requires       'IO::Stty'  => '0.0';
requires       'Time::HiRes';             # core
requires       'Getopt::Std';             # core
requires       'Getopt::Long';            # core
recommends     'Term::ANSIColor';         # core
recommends     'Term::ReadKey';
recommends     'Crypt::PWSafe3';
recommends     'File::KeePass';
recommends     'GnuPG';                   # needed for App::Tel::Passwd::Pass
recommends     'File::Which';             # needed for App::Tel::Passwd::Pass
recommends     'Passwd::Keyring::Auto';
recommends     'NetAddr::IP';
recommends     'XML::Parser';             # required for File::KeePass, it's not listed as a dependency there
recommends     'Compress::Raw::Zlib';     # required for File::KeePass, it's not listed as a dependency there
test_requires q(Test::Most) => 0.25;
