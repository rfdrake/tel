package App::Tel::Passwd::KeePass;

=head1 name

App::Tel::Passwd::KeePass - Passwd module for KeePass

=cut

use strict;
use warnings;
use Module::Load;
use Carp;

our $_debug = 0;

=head1 METHODS

=head2 new

    my $passwd = App::Tel::Passwd::KeePass->new( file => $filename, passwd => $password );

Initializes a new passwdobject.  This will return a Passwd::KeePass Object if the module
exists and return undef if it doesn't.

Requires filename and password for the file.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
    my $self = { debug => $_debug,
                 %args
    };

    if (!defined($self->{file}) || ! -r $self->{file} ) {
        $self->{file} ||= '<undefined>';
        croak "$class: Unknown file $self->{file}";
    }


    $self->{keepass} = eval {
        load File::KeePass;
        return File::KeePass->new();
    };

    if ($@) {
        croak $@;
    }

    # load failure on bad password or bad filename
    my $k = eval { $self->{keepass}->load_db($self->{file}, $self->{passwd}); };
    if ($@) {
        croak $@;
    }
    $k->unlock;
    $self->{k} = $k;

    return bless( $self, $class );
}

=head2 passwd

    $passwd->passwd($entry);

This takes the entry for a key database and returns the password.  It returns
a blank string if the entry wasn't found.

=cut

sub passwd {
    my $self = shift;
    my $k = $self->{k};
    my $entry = shift;

    my $e = $k->find_entry({title => $entry});
    return !defined($e->{'password'}) ? '' : $e->{'password'};
}

1;
