requires       'Expect'  => '>= 1.35';
requires       'IO::Stty'  => '>= 0.04';
requires       'Time::HiRes';             # core
requires       'Getopt::Std';             # core
requires       'Getopt::Long';            # core
requires       'enum' => '>= 1.12';
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

