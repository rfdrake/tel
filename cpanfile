requires       'Expect'  => '0.0';
requires       'IO::Stty'  => '0.0';
requires       'Time::HiRes';             # core
requires       'Getopt::Std';             # core
requires       'Getopt::Long';            # core
requires       'enum';
recommends     'Term::ANSIColor';         # core
recommends     'Term::ReadKey';

on 'build' => sub {
    requires 'Module::Install';
};

on 'test' => sub {
    requires 'Test::Most', '>= 0.25';
    requires 'Test::NoTabs';
    requires 'Test::EOL';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Vars';
#   github CI doesn't have the spelling dict
#    requires 'Test::Spelling';
};

on 'develop' => sub {
    requires 'Module::Install';
    requires 'Devel::Cover::Report::Coveralls';
};

feature 'hostrange', 'Hostrange Support' => sub {
    requires 'NetAddr::IP';
};

feature 'keypass', 'Keepass support' => sub {
    requires     'File::KeePass';
    requires     'XML::Parser';             # required for File::KeePass, it's not listed as a dependency there
    requires     'Compress::Raw::Zlib';     # required for File::KeePass, it's not listed as a dependency there
};

feature 'pass', 'Pass support' => sub {
    requires     'GnuPG';                   # needed for App::Tel::Passwd::Pass
    requires     'File::Which';             # needed for App::Tel::Passwd::Pass
};

feature 'keyring', 'Keyring support' => sub {
    requires 'Passwd::Keyring::Auto' => '0.70';
};

#feature 'pwsafe3', 'PWSafe3 support' => sub {
#    requires 'Crypt::PWSafe3';
#};
