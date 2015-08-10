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
    my $name = shift || '';
    my $module = eval {
        # we will accept just the argument name if need be.
        $name =~ s/_(:?file|entry|pass)//i;
        no warnings 'uninitialized';
        return Module::Load::load 'App::Tel::Passwd::'. $mapping->{lc($name)};
    };
    croak "Something went wrong with our load of passwd module $name: $@" if ($@);
    return $module;
}

=head2 load_from_profile

    my $pass = load_from_profile($profile);

Given an App::Tel profile, see if it contains entries for Passwd modules.  If
it does attempt to load them and return the password associated.

I'm not too happy with the flexibility of this, but I think it will get the
job done for right now.

=cut

sub load_from_profile {
    my $profile = shift;

    foreach my $type (keys %$mapping) {
        if (defined($profile->{$type .'_file'})) {
            my $file = $type . '_file';
            my $passwd = $type . '_passwd';
            my $entry = $type . '_entry';
            my $module = load_module $file;
            my $p = $module->new($file, $passwd);
            my $e = $p->passwd($entry);
            return $e if $e;
        }
    }
}
