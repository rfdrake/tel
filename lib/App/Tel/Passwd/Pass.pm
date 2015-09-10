package App::Tel::Passwd::Pass;

=head1 name

App::Tel::Passwd::Pass - Tel Passwd module for Pass

=cut

use strict;
use warnings;
use IPC::Run;
use File::Which qw(which);
use Carp;

our $_debug = 0;

=head1 METHODS

A note on private subroutines in this file:  Anything with two underscores
preceeding it is a private non-class sub.

=head2 new

    my $passwd = App::Tel::Passwd::Pass->new( $filename, $password );

Initializes a new passwdobject.  This will return a Passwd::Pass Object if the module
exists and return undef if it doesn't.

Requires filename and password for the file.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
    $args{file} = __find_password_store($args{file});

    my $self = { debug => $_debug,
                 gpg => which('gpg'),
                 %args
    };

    if (!$self->{gpg}) {
        croak "$class: gpg not found in system path. Is it installed?";
    }

    if (!defined($self->{file}) || ! -r $self->{file} ) {
        $self->{file} ||= '<undefined>';
        croak "$class: Can't read file $self->{file}";
    }

    $self->{password} = __run(program => $self->{gpg}, cmd_args => [ "--passphrase-fd", "0", $self->{file} ], stdin => $passwd);
    # need to detect failed password/etc here and croak on errors

    return bless( $self, $class );
}

sub __run {
    my (%args) = @_;

    my ($stdin, $stdout, $stderr);
    my @options = qw ( --quiet --no-tty --no-greeting --use-agent );
    my @cmd = ( $args{program}, @options, @{$args{cmd_args}} );

    my $harness = IPC::Run::start( \@cmd, \$stdin, \$stdout, \$stderr, IPC::Run::timeout(10) );
    if($args{stdin}) {
        $stdin .= $args{stdin};
    }

    $harness->pump();
    $harness->finish();

    say STDERR $stderr if $self->{debug};
    return $stdout;
}

sub __find_password_store {
    my $file = shift;

    return if (!defined($file));
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
    $_[0]->{password};
}

1;
