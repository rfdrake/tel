package App::Tel::Expect;

use strict;
use warnings;


=head1 NAME

App::Tel::Expect - Monkeypatching Expect to support callbacks and large buffer reads

=cut


use POSIX qw(:sys_wait_h :unistd_h); # For WNOHANG and isatty

$Expect::read_buffer_size = 10240;

# this doesn't look like my (rdrake) code.  But I don't know where it's
# originally from.

# unconverable statement
*Expect::set_cb = sub {
    my ( $self, $object, $function, $params, @args ) = @_;

    # Set an escape sequence/function combo for a read handle for interconnect.
    # Ex: $read_handle->set_seq('',\&function,\@parameters);
    ${ ${*$object}{exp_cb_Function} } = $function;
    if ( ( !defined($function) ) || ( $function eq 'undef' ) ) {
        ${ ${*$object}{exp_cb_Function} } = \&_undef;
    }
    ${ ${*$object}{exp_cb_Parameters} } = $params;
};

# I don't like overriding a crucial function of Expect and thinking it will
# work across a wide range of versions.  I could lock my Expect requirement,
# but I'd rather fix it so this isn't needed.  Expect development is pretty
# conservative, and that is probably for the best, since it needs to work for
# lots of people.

no warnings 'redefine';
# unconverable statement
*Expect::interconnect = sub {
    my (@handles) = @_;

    #  my ($handle)=(shift); call as Expect::interconnect($spawn1,$spawn2,...)
    my ( $nread );
    my ( $rout, $emask, $eout );
    my ( $escape_character_buffer );
    my ( $read_mask, $temp_mask ) = ( '', '' );

    # Get read/write handles
    foreach my $handle (@handles) {
        $temp_mask = '';
        vec( $temp_mask, $handle->fileno(), 1 ) = 1;

        # Under Linux w/ 5.001 the next line comes up w/ 'Uninit var.'.
        # It appears to be impossible to make the warning go away.
        # doing something like $temp_mask='' unless defined ($temp_mask)
        # has no effect whatsoever. This may be a bug in 5.001.
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

    # Go until we have a reason to stop
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

        # Every second? No, go until we get something from someone.
        my $nfound = select( $rout = $read_mask, undef, $eout = $emask, undef );

        # Is there anything to share?  May be -1 if interrupted by a signal...
        next CONNECT_LOOP if not defined $nfound or $nfound < 1;

        # Which handles have stuff?
        my @bits = split( //, unpack( 'b*', $rout ) );
        $eout = 0 unless defined($eout);
        my @ebits = split( //, unpack( 'b*', $eout ) );

        #    print "Ebits: $eout\r\n";
        foreach my $read_handle (@handles) {
            if ( $bits[ $read_handle->fileno() ] ) {
                $nread = sysread(
                    $read_handle, ${*$read_handle}{exp_Pty_Buffer},
                    ### tel changes here
                    $Expect::read_buffer_size
                    ### end of tel changes
                );

                ### tel changes here
                if (${*$read_handle}{exp_cb_Function}) {
                    &{ ${ ${*$read_handle}{exp_cb_Function} } }( @{ ${ ${*$read_handle}{exp_cb_Parameters} } } )
                }
                ### end of tel changes

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

            # I'm removing this because I haven't determined what causes exceptions
            # consistently.
            if (0) #$ebits[$read_handle->fileno()])
            {
                print STDERR "Got Exception reading ${*$read_handle}{exp_Pty_Handle}\r\n"
                    if ${*$read_handle}{"exp_Debug"};
                last CONNECT_LOOP
                    unless defined( ${ ${*$read_handle}{exp_Function} }{"EOF"} );
                last CONNECT_LOOP
                    unless &{ ${ ${*$read_handle}{exp_Function} }{"EOF"} }
                    ( @{ ${ ${*$read_handle}{exp_Parameters} }{"EOF"} } );
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
};

1;
