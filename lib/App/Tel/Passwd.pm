package App::Tel::Passwd;

use strict;
use warnings;
use Carp;
use Module::Load;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw ( );

=head1 NAME

App::Tel::Passwd - Methods for managing App::Tel::Passwd:: modules

=cut

my $mapping = {
    'keepass' => 'KeePass',
    'pwsafe' => 'PWSafe',
};

=head2 load_module

    my $ds = App::Tel::Passwd::load_module($password_module);

Loads the module for the specified password store type.

=cut

sub load_module {
    my $module = shift || '';
    eval {
        # we will accept just the argument name if need be.
        $module =~ s/_(:?file|entry|pass)//i;
        no warnings 'uninitialized';
        Module::Load::load 'App::Tel::Passwd::'. $mapping->{lc($module)};
    };
    croak "Something went wrong with our load of passwd module $module: $@" if ($@);
}

