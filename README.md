# Tel: A login script for routers and other devices

If you've worked at a NOC at any point in time you've probably got one of
these.  It's probably written in Expect and probably sends your username and
password to log you in.  You might have different variants for different types
of devices, or different things you need to do to a device.

This script aims to replace all of those and provide an easy to use
interactive client for most of the CLI I've encountered.

# Setup

Take the dottelrc.sample and copy it to /etc/telrc, then edit it to suit your
sites needs.  This is a baseline configuration that everyone on a bounce host
can use.  It's actually a perl file so advanced scripting is possible.  See
the STORIES.mkd file for descriptions of some of the options and examples of
their use.

Once you've copied and modified telrc, you should put tel and mktelrc
somewhere in the system $PATH for the users.

Once you're ready to go, you can instruct your users to run "mktelrc".  This
will prompt them for the username and password they use for routers, then
write them to a .telrc2 file in their home directory.

This file should be only readable by the user for security reasons, although
the very act of storing passwords for your routers in a file means you are
already defeating some security.  I advise you to only run this on a heavily
firewalled box that is only used to allow users to access routers.

Obviously, if the router supports real ssh keys or any other secure
authentication you should let the login be handled by that.  This script can
still provide value without the need to login for you.

# What do I get besides login?

## ubiquitous logout command

On cisco, logout is logout or exit.  On zhone it's exit.  On dlink it's
logout.  Casa, logout.  allied telesis, logout.  hatteras, logout or exit.  On
mikrotik, it's /quit.

On UNIX, depending on the shell, logout or exit might work.

Many devices come up with their own unique way of logging out.  Having to
figure out if it's logout, quit, /quit, exit, etc.  Can be tiring if you're
switching between devices all day.

UNIX has a shortcut that works in all shells.  Ctrl-D is end of file.  That
will logout/exit any shell you're using, and also works in many applications
to stop what you're doing and quit.

The tel script aliases Ctrl-D to run whichever logout command is used for the
device you connect to.

## fix backspace, handle ctrl-z

Dlink has a broken backspace command.  This script detects dlink and aliases
backspace to the right sequence.  Casa has a Cisco-like CLI, but doesn't
support Ctrl-Z.  This will add Ctrl-Z.

## add aliases for other commands

common tasks can be automated and even advanced commands can be scripted
through Perl's Expect.pm.  Most of that is available directly in the telrc
files without modifying the code in tel.

# clogin style arguments

## use '-c' command line to send commands

Example: 
    tel -c 'show ver; show ip int br' sw1-cisco-device

## or use -x to send a script to run

Example:
    cat <<EOF>commands.txt
    conf t
     int vlan2
      description Hello
    end
    wr
    EOF

    tel -x commands.txt sw1-cisco-device
    

# Bugs

1.  Sending a "#" to the router via -c will match that as a prompt if that is what
    your prompt is set for.  clear_accum doesn't fix this.. need to put more
    thought into it.

2.  I never added enablepass because my enable password was the same as access
    password.  Need to think about how to do this.

# Information

Use it, or modify it for your own use if you think it's useful.  Please let me
know if you find bugs or want new features.

# Copyright 2013, Robert Drake
