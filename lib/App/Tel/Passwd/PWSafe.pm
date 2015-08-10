package App::Tel::Passwd::PWSafe;

=head1 name

App::Tel::Passwd::PWSafe - module for accessing PWSafe objects

=cut

use strict;
use warnings;
use Module::Load;
use parent 'App::Tel::Passwd::Base';

our $VERSION = eval '0.2';

=head1 NOTES

Because Crypt::Random gets it's random information directly from /dev/random,
it can block when the system runs out of entropy.  This is bad for us because
the user never sees why the program is hanging.

PWSafe3 currently calls random(64) when opening an existing safe.  I've opened
github issue #9 on Crypt::PWSafe3 to see if this can be modified, but it might
be important.  The workaround for us is to require Bytes::Random::Secure
instead of Crypt::Random, which uses less entropy from /dev/random.

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
        return undef;
    }

    # see note in NOTES
    eval 'use Bytes::Random::Secure; 1';

    if ($@) {
        warn $@ if (0);
        return undef;
    }

    $self->{vault} = eval {
        load Crypt::PWSafe3;
        return Crypt::PWSafe3->new( file => $file, password => $passwd );
    };

    if ($@) {
        warn $@ if (0);
        return undef;
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
