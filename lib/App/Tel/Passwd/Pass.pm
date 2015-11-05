package App::Tel::Passwd::Pass;

=head1 name

App::Tel::Passwd::Pass - Tel Passwd module for Pass

=cut

use strict;
use warnings;
use IO::Handle;
use IO::File;
use Carp;
use Module::Load;

our $_debug = 0;

=head1 METHODS

A note on private subroutines in this file:  Anything with two underscores
proceeding it is a private non-method sub.

=head2 new

    my $passwd = App::Tel::Passwd::Pass->new( file => $filename, passwd => $password );

This will return a Passwd::Pass Object if the module exists and return undef if it doesn't.

Requires filename and password for the file.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;

    my $self = { debug => $_debug,
                 %args
    };
    $self->{file} = __find_password_store($self->{file});
    $self->{gpg} ||= ($^O=~/(freebsd|openbsd|netbsd|solaris)/) ? '/usr/local/bin/gpg' : '/usr/bin/gpg';

    if (! -x $self->{gpg}) {
        croak "$class: gpg executable not found.";
    }

    if (!defined($self->{file}) || ! -r $self->{file} ) {
        $self->{file} ||= '<undefined>';
        croak "$class: Can't read file $self->{file}";
    }

    $self->{gnupg} = eval {
        load GnuPG::Interface;
        return GnuPG::Interface->new();
    };

    if ($@) {
        croak $@;
    }

    bless( $self, $class );
    $self->{pass} = $self->_run($self->{gpg}, $self->{file}, $self->{passwd});
    return $self;
}

sub _run {
    my ($self, $call, $file, $passphrase) = @_;

    my $gnupg = $self->{gnupg};
    $gnupg->call($call);
    $gnupg->options->no_greeting(1);
    $gnupg->options->quiet(1);
    $gnupg->options->batch(1);

    # This time we'll catch the standard error for our perusing
    # as well as passing in the passphrase manually
    # as well as the status information given by GnuPG
    my ( $input, $output, $error, $passphrase_fh, $status_fh )
      = ( IO::Handle->new(),
          IO::Handle->new(),
          IO::Handle->new(),
          IO::Handle->new(),
          IO::Handle->new(),
        );

    my $handles = GnuPG::Handles->new( stdin      => $input,
                                       stdout     => $output,
                                       stderr     => $error,
                                       passphrase => $passphrase_fh,
                                       status     => $status_fh,
                                     );

    # this time we'll also demonstrate decrypting
    # a file written to disk
    # Make sure you "use IO::File" if you use this module!
    my $cipher_file = IO::File->new( $file );

    # this sets up the communication
    my $pid = $gnupg->decrypt( handles => $handles );

    # This passes in the passphrase
    print $passphrase_fh $passphrase;
    close $passphrase_fh;

    # this passes in the plaintext
    print $input $_ while <$cipher_file>;

    # this closes the communication channel,
    # indicating we are done
    close $input;
    close $cipher_file;

    my @plaintext    = <$output>;    # reading the output
    my @error_output = <$error>;     # reading the error
    my @status_info  = <$status_fh>; # read the status info
    chomp(@plaintext);

    for (@status_info) {
        croak @error_output if (/BAD_PASSPHRASE|DECRYPTION_FAILED/);
    }

    # clean up...
    close $output;
    close $error;
    close $status_fh;

    waitpid $pid, 0;  # clean up the finished GnuPG process
    return $plaintext[0];
}

sub __find_password_store {
    my $file = shift;

    return if (!defined($file));
    if ($file !~ /.gpg$/) {
        $file .= '.gpg';
    }
    # if it's an absolute path then treat it as-is.
    return $file if ($file =~ m#^/#);

    if (defined($ENV{PASSWORD_STORE_DIR})) {
        return "$ENV{PASSWORD_STORE_DIR}/$file";
    }

    return "$ENV{HOME}/.password-store/$file";
}

=head2 passwd

    $passwd->passwd($entry);

This requires a password for the router.  It will return a blank line if not
found.

=cut

sub passwd {
    $_[0]->{pass};
}

1;
