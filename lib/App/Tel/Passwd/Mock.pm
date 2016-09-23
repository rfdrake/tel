package App::Tel::Passwd::Mock;

=head1 name

App::Tel::Passwd::Mock - Passwd module for testing password modules.

=cut

use strict;
use warnings;

our $_debug = 0;
our $mock_pass = 'mock password';   # this is the password we return from passwd()
our $initial_pw = 'initialization password';  # this is the password to "unlock the file"

=head1 METHODS

=head2 new

    my $passwd = App::Tel::Passwd::Mock->new( file => $filename, passwd => $password );

Initializes a new passwd object.  This will return a Passwd::Mock Object if the module
exists and return undef if it doesn't.

Requires filename and password for the file.

=cut

sub new {
    my ($proto,%args) = @_;
    my $class = ref($proto) || $proto;
    warn "Passwords don't match\n" if ($args{passwd} ne $initial_pw);
    return bless( {}, $class );
}

=head2 passwd

    $passwd->passwd($entry);

This takes the entry for a key database and returns the password.  It returns
a blank string if the entry wasn't found.

=cut

sub passwd {
    return $mock_pass;
}

1;
