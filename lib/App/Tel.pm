package App::Tel;
use strict;
use warnings;
use Expect qw( exp_continue );
use POSIX qw(:sys_wait_h :unistd_h); # For WNOHANG
use Hash::Merge::Simple qw (merge);
use Module::Load;
use App::Tel::HostRange qw (check_hostrange);
use App::Tel::Passwd;
use App::Tel::Color;
use Time::HiRes qw ( sleep );
use v5.10;


=head1 NAME

App::Tel - A script for logging into devices

=head1 VERSION

0.201507

=cut

our $VERSION = '0.201507';


=head1 SYNOPSIS

    tel gw1-my-dev

See the README and COMMANDS files for examples of usage and ways to extend the
application.

=head1 AUTHOR

Robert Drake, C<< <rdrake at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robert Drake, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

#### GLOBALS
# For reasons related to state I needed to make $_winch_it global
# because it needs to be written to inside signals.
my $_winch_it=0;

sub _winch_handler {
    $_winch_it=1;
}

sub _winch {
    my $session = shift->{'session'};
    # these need to be wrapped in eval or you get Given filehandle is not a
    # tty in clone_winsize_from if you call winch() under a scripted
    # environment like rancid (or just under par, or anywhere there is no pty)
    eval {
        $session->slave->clone_winsize_from(\*STDIN);
        kill WINCH => $session->pid if $session->pid;
    };
    $_winch_it=0;
    $SIG{WINCH} = \&_winch_handler;
}

=head1 METHODS

=head2 new

    my $tel = App::Tel->new();

Creates a new App::Tel object.

=cut

sub new {
    my $infile = IO::File->new;
    $infile->IO::File::fdopen( \*STDIN, 'r' );

    my $self = {
        'stdin'         => Expect->exp_init($infile),
        'stdin_fileno'  => $infile->fileno,
        'connected'     => 0,
        'enabled'       => 0,
        'title_stack'   => 0,
        'log_stdout'    => 1,
    };

    bless($self, 'App::Tel');
    return $self;
}

=head2 disconnect

    $self->disconnect($hard_close);

Tears down the session gracefully and resets internal variables to their
default values.  Useful if you want to connect to another host after the first
one.

If you supply a true value, it will hard_close the session.

=cut

sub disconnect {
    my $self = shift;
    my $hard = shift;
    $self->{profile} = {};
    $self->{timeout} = $self->{opts}->{t} ? $self->{opts}->{t} : 90;
    $self->{banners} = undef;
    $self->{methods} = ();
    $self->connected(0);
    $self->{colors}=();
    $self->{enabled}=0;
    if ($self->{title_stack} > 0) {
        $self->{title_stack}--;
        print "\e[23t";
    }
    if ($hard) {
        $self->session->hard_close();
    } else {
        $self->session->soft_close();
    }
}


=head2 send

    $self->send("text\r");

Wrapper for Expect's send() method.

=cut

sub send {
    return shift->{'session'}->send(@_);
}

=head2 expect

    $self->expect("text");

Wrapper for Expect's expect() method.  If you don't specify a timeout this
will use the default script timeout.

=cut

sub expect {
    my $self = shift;
    if ($#_ < 2) {
        return $self->{'session'}->expect($self->{'timeout'}, @_);
    } else {
        return $self->{'session'}->expect(@_);
    }
}

=head2 load_config

Loads the config from /etc/telrc, /usr/local/etc/telrc, $ENV{HOME}/.telrc2, or
it can be appended to by using the environment variable TELRC, or overridden
by calling load_config with an argument:

    $self->load_config('/home/user/.my_custom_override');

=cut

sub load_config {
    my $self = shift;
    my @configs = @_;
    @configs = ( "/etc/telrc", "/usr/local/etc/telrc", "$ENV{HOME}/.telrc2") if (!@configs);
    push(@configs, $ENV{TELRC}) if (defined($ENV{TELRC}));
    our $telrc;
    my $config;

    foreach my $conf (@configs) {
        if (-r $conf) {
            require $conf;
            push(@{$config->{'telrc_file'}}, $conf);
            $config = merge($config, $telrc);
        }
    }

    if (!defined($config->{'telrc_file'})) {
        warn "No configuration files loaded. You may need to run mktelrc.";
    }

    # load global syntax highlighting things if found
    for(@{$config->{syntax}}) {
        App::Tel::Color::load_syntax($_,$self->{opts}->{d});
    }
    return $config;
}

=head2 hostname

   $hostname = $self->hostname("hostname");

Called to parse the hostname provided by the user when first making a
connection.  If the hostname has special attributes like a port designation,
it's parsed here.

This also looks up the profile for the hostname to see if it needs to be
translated because of an alias.  The final hostname is stored and returned.


=cut

sub hostname {
    my $self = shift;
    my $hostname = shift;

    if (!defined($hostname)) {
        return $self->{hostname};
    }

    $hostname =~ s#/tftpboot/##;
    $hostname =~ s/-confg//;

    if ($hostname =~ qr@(ssh|telnet)://\[([a-zA-Z0-9\-\.\:]+)\](?::(\d+))?@) {
        $self->{port} = $3 if ($3);
        $self->methods($1);
        $hostname = $2;
    } elsif ($hostname =~ qr@(ssh|telnet)://([a-zA-Z0-9\-\.]+)(?::(\d+))?@) {
        $self->{port} = $3 if ($3);
        $self->methods($1);
        $hostname = $2;
    } elsif ($hostname =~ /\[(\S+)\](?::(\d+))?/) {
        $self->{port} = $2 if ($2);
        $self->methods('telnet') if ($2);
        $hostname = $1;
    } elsif (($hostname =~ tr/://) < 2 && $hostname =~ /(\S+):(\d+)$/) {
        $self->{port} = $2;
        $self->methods('telnet');
        $hostname = $1;
    }

    # load profile based on the hostname
    $self->rtr_find($hostname);

    # if rtr->hostname is defined as code then call it to determine the real hostname
    # if it's not then treat it as an alias.
    if (defined($self->profile->{hostname})) {
        if (ref($self->profile->{hostname}) eq 'CODE') {
            $hostname = &{$self->profile->{hostname}}($hostname);
        } else {
            $hostname = $self->profile->{hostname};
        }
    }
    $self->{hostname} = $hostname;
    return $self->{hostname};
}

=head2 methods

    $self->methods();

This is used to determine the method used to connect to the remote device.
Generally, the CLI argument -m has the highest priority.  The uri should be
second, profiles third, and the defaults would be last.  If called without
arguments it will return whatever the currently decided method array is.  If
called with an argument that will be set as the new method array.

If you call it multiple times it won't change right now.  I may need to
rethink this later but right now it works with the way the program flows.
$self->disconnect removes all methods so connecting to another router will run
this again.

    $self->methods('ssh', 'telnet');

=cut

sub methods {
    my $self = shift;

    if (@_) {
        @{$self->{methods}} = @_;
    } elsif (defined($self->{methods})) {
        return $self->{methods};
    } elsif ($self->{opts}->{m}) {
        $self->{methods} = [ $self->{opts}->{m} ];
    } elsif (defined($self->{'profile'}->{method})) {
        @{$self->{methods}} = split(/,/, $self->{'profile'}->{method});
    } else {
        $self->{methods} = [ 'ssh', 'telnet' ];
    }

    return $self->{methods};
}

sub _banners {
    my $self = shift;
    return $self->{banners} if ($self->{banners});
    my $config = $self->{'config'};

    # if there are no banners then we want to return an empty list
    $self->{banners} = [];
    while (my ($regex, $profile) = each %{$config->{banners}}) {
        push @{$self->{banners}}, [ $regex, sub { $self->profile($profile); exp_continue; } ];
    }
    return $self->{banners};
}

=head2 rtr_find

    my $profile = $self->rtr_find($regex);

Find the router by hostname/regex and load the config associated with it.
Load a profile for it if there is one.

=cut

sub rtr_find {
    my $self = shift;
    my $host = shift;
    my $profile = $self->{'profile'};
    my $config = $self->{'config'};

    foreach my $h (@{$config->{rtr}}) {
        my $h2 = $h->{regex};
        if ($host =~ /$h2/i || check_hostrange($h2, $host)) {
            $profile=merge($profile, $h);
            last;
        }
    }
    $self->{'profile'}=$profile;

    # if the host specified a profile to load then load it here
    if (defined($profile->{profile})) {
        return $self->profile($profile->{profile});
    }

    return $profile;
}

=head2 profile

   $profile = $self->profile;
   $profile = $self->profile('profilename', $replace);

Called without arguments this will return the current profile.  If called with
a profilename it will load that new profile on top of whatever profile
currently exists.  You can set the second argument to true if you want to
replace the current profile with the new one.

=cut

sub profile {
    my $self = shift;
    my $profile_arg = shift;
    my $replace = shift;
    my $stdin = $self->{'stdin'};
    my $config = $self->{'config'};
    my $session = $self->{'session'};
    my $profile = $self->{'profile'};

    return $profile if (!defined($profile_arg));

    if ($replace) {
        # wipe out the old profile if we're replacing it.
        $profile = {};
    }

    foreach(split(/\+/, $profile_arg)) {
        $profile = merge($profile, $config->{profile}{$_});

        # load handlers for profile
        if ($profile->{handlers}) {
            foreach my $v (keys %{$profile->{handlers}}) {
                $stdin->set_seq($v, $profile->{handlers}{$v}, [ \$self ]);
            }
        }
        # load syntax highlight
        if ($profile->{syntax}) {
            App::Tel::Color::load_syntax($profile->{syntax},$self->{opts}->{d});
        }
        $profile->{profile_name}=$_;
    }

    # add some sane defaults if the profile doesn't have them
    $profile->{'user'} ||= $ENV{'USER'};
    $self->{'profile'}=$profile;
    return $profile;
}

sub _stty_rows {
    my $new_rows = shift;
    eval {
        Module::Load::load Term::ReadKey;
        my ($columns, $rows, $xpix, $ypix) = GetTerminalSize(\*STDOUT);
        SetTerminalSize($columns, $new_rows, $xpix, $ypix, \*STDOUT);
    };

    warn $@ if ($@);
}

=head2 password

    my $password = $self->password;

This pulls the password from the config.  If the password is blank it checks
to see if you have a password manager, then tries to load the password from
there.  It then tries to use an OS keyring.

By default it will pull the regular password.  To pull the enable password
you can call it with $self->password('enable');

=cut

sub password {
    my $self = shift;
    my $type = shift;
    my $profile = $self->profile;
    my $router = $self->{hostname};

    $type ||= 'password';

    warn "Unknown password type $type" if ($type ne 'password' && $type ne 'enable');

    if (defined($profile->{$type}) && $profile->{$type} ne '') {
        return $profile->{$type};
    }

    # if enable is blank but password has something then use the same password
    # for enable.
    if ($type eq 'enable' and $profile->{$type} eq '' && $profile->{'password'} ne '') {
        return $profile->{'password'};
    }

    # if we get here, the password is blank so try other means
    my $pass = App::Tel::Passwd::load_from_profile($profile);
    if ($pass ne '') {
        return $pass;
    }

    # I was wondering how to decide what to prompt for, but I think it should
    # be whichever profile loaded.  So maybe we check for hostname and check
    # for profile name and then save as profile name. If they want to be
    # explicit they should specify the password format as KEYRING or
    # something.. I dunno.
    App::Tel::Passwd::keyring($profile->{user}, $profile->{profile_name}, $profile->{profile_name});

    # if they make it here and still don't have a password then none was
    # defined anywhere and we probably should prompt for one.  Consider
    # turning off echo then normal read.
    return App::Tel::Passwd::input_password($router);
}

=head2 session

    my $session = $self->session;

Expect won't let you reuse a connection that has spawned a process, so you
can call this with an argument to reset the session.  If called without an
argument it will return the current session (If it exists) or create a new
session.

=cut

sub session {
    my $self = shift;
    my $renew = shift;

    return $self->{'session'} if (!$renew && defined($self->{'session'}));
    my $session = $self->{'session'};

    $session->soft_close() if ($session && $session->pid());
    $session = new Expect;

    # install sig handler for window size change
    $SIG{WINCH} = \&_winch_handler;


    $session->log_stdout(1);
    $self->{'session'} = $session;
    return $session;
}

=head2 connect

    my $session = $self->connect('routername');

This sets up the session.  If there already is a session open it closes and opens a new one.

=cut

sub connect {
    my $self = shift;
    my @arguments = shift;

    $self->connected(0);
    my $session = $self->session(1);
    $session->spawn(@arguments);
    return $session;
}

=head2 connected

    if ($self->connected);
or
    $self->connected(1);

Returns connection status, or sets the status to whatever value is supplied to
the method.

Note: This isn't the session state, but an indicator that our session has
gotten through the login stage and is now waiting for input.  i.e., the router
is at a prompt of some kind.

=cut

sub connected {
    my $self = shift;
    my $status = shift;
    if ($status) {
        $self->{connected}=$status;
    }

    return $self->{connected};
}

=head2 enable

    my $enabled = $self->enable;

if enablecmd is set then this method attempts to enable the user

=cut

sub enable {
    my $self = shift;
    my $profile = $self->profile;

    if ($profile->{enablecmd}) {
        $self->send($profile->{enablecmd} . "\r");

        $profile->{ena_username_prompt} ||= qr/[Uu]ser[Nn]ame:|Login:/;
        $profile->{ena_password_prompt} ||= qr/[Pp]ass[Ww]ord/;

        # we need to be able to handle routers that prompt for username and password
        # need to check the results to see if enable succeeded
        $self->expect($self->{timeout},
                [ $profile->{ena_username_prompt} => sub { $self->send("$profile->{user}\r"); exp_continue; } ],
                [ $profile->{ena_password_prompt} => sub { $self->send($self->password('enable') . "\r"); } ]
        );
    }

    $self->{enabled}=1;
    return $self->{enabled};
}

=head2 login

    my $something = $self->login("hostname");

Cycles through the connection methods trying each in the order specified by
the profile until we successfully connect to the host.  Returns connected
status (true or false).

=cut

sub login {
    my $self = shift;
    my $hostname = shift;

    # dumb stuff to alias $rtr to the contents of $self->{'profile'}
    # needed because we reload the profile in the expect loop and can't update
    # the alias.
    our $rtr;
    *rtr = \$self->{'profile'};

    my $ssho = '-o StrictHostKeyChecking=no';
    if (defined($rtr->{sshoptions}) && scalar $rtr->{sshoptions} > 0) {
        my @sshoptions = @{$rtr->{sshoptions}};
        $ssho = '-o '. join(' -o ', @sshoptions);
    }

    my $cipher = $rtr->{ciphertype} ? ('-c ' . $rtr->{ciphertype}) : '';

    # because we use last METHOD; in anonymous subs this suppresses the
    # warning of "exiting subroutine via last;"
    no warnings 'exiting';
    # handle MOTD profile loading, and other things parsed from the config
    my @dynamic;
    if (defined($rtr->{prompt})) {
        push @dynamic, [ qr/$rtr->{prompt}/, sub { $self->connected(1); last METHOD; } ];
    }

    # handle prompts in foreign languages or other things we didn't think of
    $rtr->{username_prompt} ||= qr/[Uu]ser[Nn]ame:|[Ll]ogin:/;
    $rtr->{password_prompt} ||= qr/[Pp]ass[Ww]ord/;

    $self->{port} ||= $self->{opts}->{p}; # get port from CLI
    $self->{port} ||= $rtr->{port};       # or the profile
    # if it's not set in the profile or CLI above, it gets set in the
    # method below, but needs to be reset on each loop to change from
    # telnet to ssh defaults

    METHOD: for (@{$self->methods}) {
        my $allied_shit=0;

        my $p = $self->{port};

        if ($_ eq 'ssh')        { $p ||= 22; $self->connect("ssh -p $p -l $rtr->{user} $ssho $cipher $hostname"); }
        elsif ($_ eq 'telnet')  { $p ||= 23; $self->connect("telnet $hostname $p"); }
        # for testing. can pass an expect script to the other side and use it's output as our input.
        elsif ($_ eq 'exec')    { $self->connect($hostname); }
        else { die "No program defined for method $_\n"; }

        # suppress stdout if needed
        $self->{'session'}->log_stdout($self->{log_stdout});

        # need to make this optional
        # also need to make it display whatever the user cares about.
        print "\e[22t\033]0;$_ $hostname\007";
        $self->{title_stack}++;
        $SIG{INT} = sub { for (1..$self->{title_stack}) { print "\e[23t"; } $self->{title_stack}=0; };
        $self->expect($self->{timeout},
                @{$self->_banners},
                @dynamic,
                # fucking shitty allied telesyn
                [ qr/User Access Verification - RADIUS/ => sub { $allied_shit=1;
                    $self->send("$rtr->{user}\r".$self->password()."\r"); exp_continue } ],
                [ qr/User Access Verification - Local/ => sub {
                    $self->send("$rtr->{user}\r".$self->password()."\r"); $self->connected(1); last METHOD; } ],
                [ $rtr->{username_prompt} => sub {
                    $self->send("$rtr->{user}\r") unless($allied_shit); exp_continue; } ],
                [ $rtr->{password_prompt} => sub {
                    if ($allied_shit) {
                        exp_continue;
                    } else {
                        $self->send($self->password() ."\r");
                        $self->connected(1);
                        last METHOD;
                    }
                } ],
                [ qr/Name or service not known|hostname nor servname provided, or not known|could not resolve / => sub
                    {
                        # if host lookup fails then check to see if there is an alternate method defined
                        if ($rtr->{hostsearch} && !$rtr->{hostsearched}) {
                            $hostname = &{$rtr->{hostsearch}}($hostname);
                            $rtr->{hostsearched}=1;
                            redo METHOD;
                        } else {
                            warn "unknown host: $hostname\n";
                            # skip to next host if this one doesn't exist
                            last METHOD;
                       }
                    }
                ],
                [ qr/Corrupted/ => sub { next METHOD; } ],
                # almost never needed anymore.  Some people might not want a
                # fallback to des.  If anyone does we need to make it optional
                #[ qr/cipher type \S+ not supported/ => sub { $rtr->{ciphertype}="des"; redo METHOD; } ],
                [ qr/ssh_exchange_identification/ => sub { next METHOD; } ],
                [ qr/[Cc]onnection (refused|closed)/ => sub { next METHOD; } ],
                [ qr/key_verify failed/ => sub { next METHOD; } ],
                [ 'eof' => sub { next METHOD; } ],
                [ 'timeout' => sub { next METHOD; } ],
        );
    }

    $rtr->{logoutcmd} ||= "logout";
    $rtr->{prompt} ||= '#';

    warn "Connection to $hostname failed.\n" if !$self->connected;
    return $self->connected;
}

=head2 logging

    $self->logging('filename');

Turns on logging for this session.  If you specify a filename it will log to
/tmp/<filename>.log, otherwise it will use /tmp/<hostname>.log.

=cut

sub logging {
    my $self = shift;
    my $file = shift;
    $file ||= $self->{hostname};
    unlink ("/tmp/$file.log") if (-f "/tmp/$file.log");
    $self->session->log_file("/tmp/$file.log");
}

=head2 interact

    $self->interact($input, $escape);

This is a copy of Expect's interact() command.  It's been rewritten in parts
to customize it for our needs, but might be very similar otherwise.  It's
mainly a setup script for the call to interconnect().

=cut

sub interact {
    my $self = shift;
    my $session = $self->{'session'};
    my $in_object = shift;
    my $escape_sequence = shift;

    my @old_group = $session->set_group();
    # we know the input is STDIN and that it's an object.
    my $out_object = Expect->exp_init(\*STDOUT);
    $out_object->manual_stty(1);
    $session->set_group($out_object);

    $in_object->set_group($session);
    $in_object->set_seq($escape_sequence,undef) if defined($escape_sequence);
    # interconnect normally sets stty -echo raw. Interact really sort
    # of implies we don't do that by default. If anyone wanted to they could
    # set it before calling interact, of use interconnect directly.
    my $old_manual_stty_val = $session->manual_stty();
    $session->manual_stty(1);
    # I think this is right. Don't send stuff from in_obj to stdout by default.
    # in theory whatever 'session' is should echo what's going on.
    my $old_log_stdout_val = $session->log_stdout();
    $session->log_stdout(0);
    $in_object->log_stdout(0);
    # Allow for the setting of an optional EOF escape function.
    #  $in_object->set_seq('EOF',undef);
    #  $session->set_seq('EOF',undef);
    $self->interconnect($in_object);
    $session->log_stdout($old_log_stdout_val);
    $session->set_group(@old_group);
    # If old_group was undef, make sure that occurs. This is a slight hack since
    # it modifies the value directly.
    # Normally an undef passed to set_group will return the current groups.
    # It is possible that it may be of worth to make it possible to undef
    # The current group without doing this.
    unless (@old_group) {
        @{${*$session}{exp_Listen_Group}} = ();
    }
    $session->manual_stty($old_manual_stty_val);
}

=head2 interconnect

    $self->interconnect(@handles);

This is a copy of Expect's interconnect() method that has been modified to
support the new things we needed.  The main differences are colorize and our
winch handler.

Future versions might support AnyEvent::IO or AnyEvent::Socket, but I might
contribute that back to Expect's core stuff.  I might also try to figure out
how to make the colorize stuff more hookable so we could use Expect's methods
without rewriting them.

=cut

sub interconnect {
    my $self = shift;
    my @handles = ($self->{'session'}, $_[0]);

    my ( $nread );
    my ( $rout, $emask, $eout );
    my ( $escape_character_buffer );
    my ( $read_mask, $temp_mask ) = ( '', '' );

    # Get read/write handles
    foreach my $handle (@handles) {
        $temp_mask = '';
        vec( $temp_mask, $handle->fileno(), 1 ) = 1;
        $read_mask = $read_mask | $temp_mask;
    }
    if ($Expect::Debug) {
        print STDERR "Read handles:\r\n";
        foreach my $handle (@handles) {
            print STDERR "\tRead handle: ";
            print STDERR "'${*$handle}{exp_Pty_Handle}'\r\n";
            print STDERR "\t\tListen Handles:";
            foreach my $write_handle ( @{ ${*$handle}{exp_Listen_Group} } ) {
                print STDERR " '${*$write_handle}{exp_Pty_Handle}'";
            }
            print STDERR ".\r\n";
        }
    }

    #  I think if we don't set raw/-echo here we may have trouble. We don't
    # want a bunch of echoing crap making all the handles jabber at each other.
    foreach my $handle (@handles) {
        unless ( ${*$handle}{"exp_Manual_Stty"} ) {

            # This is probably O/S specific.
            ${*$handle}{exp_Stored_Stty} = $handle->exp_stty('-g');
            print STDERR "Setting tty for ${*$handle}{exp_Pty_Handle} to 'raw -echo'.\r\n"
                if ${*$handle}{"exp_Debug"};
            $handle->exp_stty("raw -echo");
        }
        foreach my $write_handle ( @{ ${*$handle}{exp_Listen_Group} } ) {
            unless ( ${*$write_handle}{"exp_Manual_Stty"} ) {
                ${*$write_handle}{exp_Stored_Stty} =
                    $write_handle->exp_stty('-g');
                print STDERR "Setting ${*$write_handle}{exp_Pty_Handle} to 'raw -echo'.\r\n"
                    if ${*$handle}{"exp_Debug"};
                $write_handle->exp_stty("raw -echo");
            }
        }
    }

    print STDERR "Attempting interconnection\r\n" if $Expect::Debug;

    # Wait until the process dies or we get EOF
    # In the case of !${*$handle}{exp_Pid} it means
    # the handle was exp_inited instead of spawned.
    CONNECT_LOOP:
    while (1) {

        # test each handle to see if it's still alive.
        foreach my $read_handle (@handles) {
            waitpid( ${*$read_handle}{exp_Pid}, WNOHANG )
                if ( exists( ${*$read_handle}{exp_Pid} )
                and ${*$read_handle}{exp_Pid} );
            if (    exists( ${*$read_handle}{exp_Pid} )
                and ( ${*$read_handle}{exp_Pid} )
                and ( !kill( 0, ${*$read_handle}{exp_Pid} ) ) )
            {
                print STDERR
                    "Got EOF (${*$read_handle}{exp_Pty_Handle} died) reading ${*$read_handle}{exp_Pty_Handle}\r\n"
                    if ${*$read_handle}{"exp_Debug"};
                last CONNECT_LOOP
                    unless defined( ${ ${*$read_handle}{exp_Function} }{"EOF"} );
                last CONNECT_LOOP
                    unless &{ ${ ${*$read_handle}{exp_Function} }{"EOF"} }
                    ( @{ ${ ${*$read_handle}{exp_Parameters} }{"EOF"} } );
            }
        }

        my $nfound = select( $rout = $read_mask, undef, $eout = $emask, undef );

        # Is there anything to share?  May be -1 if interrupted by a signal...
        $self->_winch() if $_winch_it;
        next CONNECT_LOOP if not defined $nfound or $nfound < 1;

        # Which handles have stuff?
        my @bits = split( //, unpack( 'b*', $rout ) );
        #$eout = 0 unless defined($eout);
        #my @ebits = split( //, unpack( 'b*', $eout ) );
        #    print "Ebits: $eout\r\n";
        foreach my $read_handle (@handles) {
            if ( $bits[ $read_handle->fileno() ] ) {
                # it would be nice if we could say read until TELNET_GA or the
                # equivilant, but that's not something we can be sure would be
                # there.  Cisco doesn't always fill the buffers just because
                # they could, so there is a chance even though we tell them we
                # can accept 10k they'll only send 1k and we split the middle
                # of a regex.  With escape sequences that isn't a big deal.
                # With colorizing it causes problems because it's data already
                # written to the screen so you can't take it back (without big
                # work)
                $nread = sysread(
                    $read_handle, ${*$read_handle}{exp_Pty_Buffer},
                    10240
                );

                # don't bother trying to colorize input from the user
                if ($read_handle->fileno() != $self->{stdin_fileno}) {
                    foreach my $color (@{$self->{colors}}) {
                        ${*$read_handle}{exp_Pty_Buffer} = $color->colorize(${*$read_handle}{exp_Pty_Buffer});
                    }
                }
                # Appease perl -w
                $nread = 0 unless defined($nread);
                print STDERR "interconnect: read $nread byte(s) from ${*$read_handle}{exp_Pty_Handle}.\r\n"
                    if ${*$read_handle}{"exp_Debug"} > 1;

                # Test for escape seq. before printing.
                # Appease perl -w
                $escape_character_buffer = ''
                    unless defined($escape_character_buffer);
                $escape_character_buffer .= ${*$read_handle}{exp_Pty_Buffer};
                foreach my $escape_sequence ( keys( %{ ${*$read_handle}{exp_Function} } ) ) {
                    print STDERR "Tested escape sequence $escape_sequence from ${*$read_handle}{exp_Pty_Handle}"
                        if ${*$read_handle}{"exp_Debug"} > 1;

                    # Make sure it doesn't grow out of bounds.
                    $escape_character_buffer = $read_handle->_trim_length(
                        $escape_character_buffer,
                        ${*$read_handle}{"exp_Max_Accum"}
                    ) if ( ${*$read_handle}{"exp_Max_Accum"} );
                    if ( $escape_character_buffer =~ /($escape_sequence)/ ) {
                        my $match = $1;
                        if ( ${*$read_handle}{"exp_Debug"} ) {
                            print STDERR
                                "\r\ninterconnect got escape sequence from ${*$read_handle}{exp_Pty_Handle}.\r\n";

                            # I'm going to make the esc. seq. pretty because it will
                            # probably contain unprintable characters.
                            print STDERR "\tEscape Sequence: '"
                                . _trim_length(
                                undef,
                                _make_readable($escape_sequence)
                                ) . "'\r\n";
                            print STDERR "\tMatched by string: '" . _trim_length( undef, _make_readable($match) ) . "'\r\n";
                        }

                        # Print out stuff before the escape.
                        # Keep in mind that the sequence may have been split up
                        # over several reads.
                        # Let's get rid of it from this read. If part of it was
                        # in the last read there's not a lot we can do about it now.
                        if ( ${*$read_handle}{exp_Pty_Buffer} =~ /([\w\W]*)($escape_sequence)/ ) {
                            $read_handle->_print_handles($1);
                        } else {
                            $read_handle->_print_handles( ${*$read_handle}{exp_Pty_Buffer} );
                        }

                        # Clear the buffer so no more matches can be made and it will
                        # only be printed one time.
                        ${*$read_handle}{exp_Pty_Buffer} = '';
                        $escape_character_buffer = '';

                        # Do the function here. Must return non-zero to continue.
                        # More cool syntax. Maybe I should turn these in to objects.
                        last CONNECT_LOOP
                            unless &{ ${ ${*$read_handle}{exp_Function} }{$escape_sequence} }
                            ( @{ ${ ${*$read_handle}{exp_Parameters} }{$escape_sequence} } );
                    }
                }
                $nread = 0 unless defined($nread); # Appease perl -w?
                waitpid( ${*$read_handle}{exp_Pid}, WNOHANG )
                    if ( defined( ${*$read_handle}{exp_Pid} )
                    && ${*$read_handle}{exp_Pid} );
                if ( $nread == 0 ) {
                    print STDERR "Got EOF reading ${*$read_handle}{exp_Pty_Handle}\r\n"
                        if ${*$read_handle}{"exp_Debug"};
                    last CONNECT_LOOP
                        unless defined( ${ ${*$read_handle}{exp_Function} }{"EOF"} );
                    last CONNECT_LOOP
                        unless &{ ${ ${*$read_handle}{exp_Function} }{"EOF"} }
                        ( @{ ${ ${*$read_handle}{exp_Parameters} }{"EOF"} } );
                }
                last CONNECT_LOOP if ( $nread < 0 ); # This would be an error
                $read_handle->_print_handles( ${*$read_handle}{exp_Pty_Buffer} );
            }
        }
    }
    foreach my $handle (@handles) {
        unless ( ${*$handle}{"exp_Manual_Stty"} ) {
            $handle->exp_stty( ${*$handle}{exp_Stored_Stty} );
        }
        foreach my $write_handle ( @{ ${*$handle}{exp_Listen_Group} } ) {
            unless ( ${*$write_handle}{"exp_Manual_Stty"} ) {
                $write_handle->exp_stty( ${*$write_handle}{exp_Stored_Stty} );
            }
        }
    }

    return;
}

=head2 run_commands

    $self->run_commands(@commands);

TODO: Document this


=cut

sub run_commands {
    my $self = shift;
    my $opts = $self->{opts};

    foreach my $arg (@_) {
        $arg =~ s/\\r/\r/g; # fix for reload\ry.  I believe 'perldoc quotemeta' explains why this happens
        chomp($arg);
        $self->send("$arg\r");
        $self->expect($self->{timeout},'-re', $self->profile->{prompt});
        sleep($opts->{s}) if ($opts->{s});
    }
}

=head2 control_loop

    $self->control_loop();

This is where control should be passed once the session is logged in.  This
handles CLI commands passed via the -c option, or scripts executed with the -x
option.  It also handles autocommands passed via either option -a on the
command line, or via autocmds in the profile.

Calling this without any commands will just run interact()

=cut

sub control_loop {
    my $self = shift;
    my $profile = $self->profile;
    my $opts = $self->{opts};
    my $prompt = $profile->{prompt};
    my $pagercmd = $profile->{pagercmd};
    my $autocmds;
    my @args;

    if ($opts->{a}) {
        $autocmds = [ split(/;/, $opts->{a}) ];
    } else {
        $autocmds = $profile->{autocmds};
    }

    $self->_winch();

    # should -c override -x or be additive? or error if both are specified?

    @args = split(/;/, $opts->{c}) if ($opts->{c});

    if ($opts->{x}) {
        for (@$opts->{x}) {
            open(my $X, '<', $_) || die "Can't open file $_\n";
            push(@args,<$X>);
            close $X;
        }
    }

    if (@args) {
        $self->expect($self->{timeout},'-re',$prompt);
        if (ref($pagercmd) eq 'CODE') {
            $pagercmd->();
        } elsif ($pagercmd) {
            $self->run_commands("$pagercmd\r");
        }
        $self->run_commands(@args);
        $self->send($profile->{logoutcmd} ."\r");
    } else {
        die 'STDIN Not a tty' if (!POSIX::isatty($self->{stdin}));
        if ($autocmds) {
            $self->expect($self->{timeout},'-re',$prompt);
            $self->run_commands(@$autocmds);
        }
        $self->interact($self->{stdin}, '\cD');
        # q\b is to end anything that's at a More prompt or other dialog and
        # get you back to the command prompt
        # would be nice to detect if the session is closing down and not send
        # this.  I've tried checking for session and session->pid but they
        # both still exist at this point so unless we wait for soft_close
        # we're kinda stuck doing this.
        $self->send("q\b" . $profile->{logoutcmd}. "\r");
    }
}

=head2 handle_backspace

Handle backspace for routers that use ^H

=cut

sub handle_backspace {
    ${$_[0]}->send("\b");
    return 1;
}

=head2 handle_ctrl_z

Handle ctrl_z for non-cisco boxes

=cut

sub handle_ctrl_z {
    ${$_[0]}->send("exit\r");
    return 1;
}

1;
