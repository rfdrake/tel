package App::Tel::Passwd::Base;

=head1 name

App::Tel::Passwd::Base - parent stub and examples for Passwd modules

=cut

use strict;
use warnings;

=head1 METHODS

=head2 new

    my $passwdobject = App::Tel::Passwd::Base->new( $filename, $password );

Initializes a new passwdobject.  This will return a Passwd::Base if the module
exists and return undef if it doesn't.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return bless( { }, $class);
}

=head2 passwd

    $passwdobject->passwd($entry);

This takes the entry for a database key and returns a password.  It returns a
blank string if the entry was not found.

=cut


sub passwd {
    my $self = shift;
    my $entry = shift;

    return;
}

1;
