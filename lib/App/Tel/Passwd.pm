package App::Tel::Passwd;

use strict;
use warnings;
use Carp;
use Module::Load;
use POSIX qw(); # For isatty
use IO::Stty;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw ( keyring input_password );

=head1 NAME

App::Tel::Passwd - Methods for managing App::Tel::Passwd:: modules

=cut

my $plugins = [ 'KeePass', 'PWSafe' ];

=head2 load_module

    my $name = App::Tel::Passwd::load_module($password_module, $file, $passwd);

Loads the module for the specified password store type.  Returns the module's
namespace.

=cut

sub load_module {
    my ($type, $file, $passwd) = @_;
    no warnings 'uninitialized';
    my $mod = 'App::Tel::Passwd::'. $type;
    my $load = eval {
        Module::Load::load $mod;
        $mod->new(file => $file, passwd => $passwd);
    };
    croak "Something went wrong with our load of passwd module $type: $@" if ($@);
    return $load;
}

=head2 input_password

    my $password = input_password($prompt);

Prompts the user for a password then disables local echo on STDIN, reads a
line and returns it.

=cut


sub input_password {
    my $prompt = shift;
    $prompt ||= '';
    die 'STDIN not a tty' if (!POSIX::isatty(\*STDIN));
    my $old_mode=IO::Stty::stty(\*STDIN,'-g');
    print "Enter password for $prompt: ";
    IO::Stty::stty(\*STDIN,'-echo');
    chomp(my $password=<STDIN>);
    IO::Stty::stty(\*STDIN,$old_mode);
    return $password;
}

=head2 keyring

    my $password = keyring($user, $domain, $group);

Reads a password from a keyring using Passwd::Keyring::Auto if it's available.
If the password isn't found the user is prompted to enter a password, then we
try to store it in the keyring.

=cut

sub keyring {
    my ($user, $domain, $group) = @_;

    # TODO: needs to warn on some kind of failure?
    eval {
        load Passwd::Keyring::Auto, 'get_keyring';
        my $keyring = get_keyring(app=>"tel script", group=>$group);
        my $pass = $keyring->get_password($user, $domain);
        if (!$pass) {
            $pass = input_password($domain);
            $keyring->set_password($user, $pass, $domain);
        }
        return $pass;
    };
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

    foreach my $plugin (@$plugins) {
        my $type = lc($plugin);
        if (defined($profile->{$type .'_file'})) {
            my $file = $type . '_file';
            my $entry = $type . '_entry';
            my $safe_password = $profile->{$type . '_passwd'};

            if ($safe_password eq 'KEYRING') {
                $safe_password = keyring($type,$type,$type);
            }

            my $mod = load_module $plugin, $profile->{$file}, $safe_password;
            my $e = $mod->passwd($profile->{$entry});
            return $e if $e;
        }
    }
}

