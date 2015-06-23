package App::Tel::PasswdObject;

=head1 name

App::Tel::PasswdObject - parent stub and examples for Passwd modules

=cut

use strict;
use warnings;

our $VERSION = eval '0.1';

=head1 methods

=head2 new

    my $passwdobject = new App::Tel::PasswdObject;

Initializes a new passwdobject.  This will return a PasswdObject if the module
exists and return undef if it doesn't.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return bless( { }, $class);
}

=head2 passwd

    $passwdobject->passwd($file, $passwd, $entry);

This takes the file name, password, and 'entry' for a key database and returns
a password.

=cut


sub passwd {
    my $self = shift;
    my $file = shift;
    my $passwd = shift;
    my $entry = shift;

    return undef;
}

1;
