package App::Tel::Passwd::PWSafe;

=head1 name

App::Tel::Passwd::PWSafe - module for accessing PWSafe objects

=cut

use strict;
use warnings;
use Carp;
use Module::Load;
use parent 'App::Tel::Passwd::Base';

=head1 METHODS

=head2 new

    my $passwd = App::Tel::Passwd::PWSafe->new( $filename, $password );

Initializes a new passwd object.  This will return a Passwd::PWSafe Object if the module
exists and return undef if it doesn't.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $file = shift;
    my $passwd = shift;
    my $self = {};

    # unknown or non-existant file returns undef.  Crypt::PWSafe3 will
    # otherwise attempt to generate a new safe with this filename.
    if (!defined($file) || ! -r $file ) {
        return;
    }

    $self->{vault} = eval {
        load Crypt::PWSafe3;
        return Crypt::PWSafe3->new( file => $file, password => $passwd );
    };

    if ($@) {
        carp $@ if (0);
        return;
    }
    return bless( $self, $class );
}

=head2 passwd

    $passwd->passwd($entry);

This takes the entry for a database key and returns a password.  It returns a
blank string if the entry wasn't found.

=cut


sub passwd {
    my $self = shift;
    my $entry = shift;

    foreach my $record ($self->{vault}->getrecords()) {
        if ($record->title eq $entry) {
            return $record->passwd;
        }
    }
}

1;