package App::Tel::Passwd::PWSafe;

=head1 name

App::Tel::Passwd::PWSafe - module for accessing PWSafe objects

=cut

use strict;
use warnings;
use Carp;
use Module::Load;

our $_debug = 0;

=head1 METHODS

=head2 new

    my $passwd = App::Tel::Passwd::PWSafe->new( file => $filename, passwd => $password );

Initializes a new passwd object.  This will return a Passwd::PWSafe Object if the module
exists and return undef if it doesn't.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %args = @_;
    my $self = { debug => $_debug,
                 %args
    };

    # unknown or non-existant file returns undef.  Crypt::PWSafe3 will
    # otherwise attempt to generate a new safe with this filename.
    if (!defined($self->{file}) || ! -r $self->{file} ) {
        $self->{file} ||= '<undefined>';
        croak "$class: Can't read file " . $self->{file};
    }

    $self->{vault} = eval {
        load Crypt::PWSafe3;
        return Crypt::PWSafe3->new( file => $self->{file}, password => $self->{passwd} );
    };

    if ($@) {
        croak $@;
    }
    return bless( $self, $class );
}

=head2 passwd

    $passwd->passwd($entry);

This takes the entry for a database key and returns a password.  It returns a
blank string if the entry wasn't found.

=cut


sub passwd {
    my ($self, $entry) = @_;

    foreach my $record ($self->{vault}->getrecords()) {
        if ($record->title eq $entry) {
            return $record->passwd;
        }
    }
}

1;
