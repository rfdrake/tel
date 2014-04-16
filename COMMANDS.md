# Why doesn't this use modules

I'm trying to keep the dependencies down and keep the feel of this being a
script.  There have been times when I've realized that objects would better
suit the circumstances of what I was doing, but I've stayed away from that to
keep this friendly for the NOC people who just want an executable to run.

# flags and things

This is a list of possible flags you might include in telrc to provide various
features for different types of devices.

## banner

The banner flag is a global flag that is used to load a profile if it's seen
during the login of a device.  It allows regular expressions.

I needed a way to detect some devices when I connect to them.  Normally we use
regex on the hostname to see if it's a switch and use the switch profile, but
in some cases there may be quirks from one switch vendor, so rather than
overriding everything, or trying to detect the device type after login, we use
hints from the devices telnet banner to determine what it is and load it's
profile.

Example:  Dlink doesn't use the normal backspace, it uses \b.  We check for a
banner screen that says DES-3(\d\d\d) and load the dlink profile when we see
it.

## hostname

Hostname is a router directive.  It has two uses which are outlined below.

### hostname (aliases)

Sometimes you want to connect to a device with a hostname that isn't in DNS.
Maybe the DNS name is long and you want to abbriviate it, or maybe you want to
set options, like username or login method when you connect on one name, then
use different options on another name.  You can do this with the hostname
directive.

You can also use this to provide a port in the case that

    { 'regex' => '^gw1-dinglehopper', 'hostname' => 'shiny' },

### hostname (CODE ref)

In very rare cases, you may want to take the hostname and rewrite it for
some reason.  If you need to do this you can pass an anonymous subroutine
as the hostname and tel will run it with the original hostname as the
argument.  The return value should be the new hostname.

My use case for this is probably unique so I won't mention it, but as an
example, let's say you wanted to take anything that started with C15 and
replace it with a circuit ID from your database:

    { 'regex' => '^c15', 'hostname' => sub { use DBLookup qw (circuitid); return curcuitid($_[0]); } }

Even this is unrealistic, but I can't think of something generic to show right
now.

## handlers

This is a rtr or profile directive.  It's used to override a key sequence.
It takes a key or key combination and a function reference for arguments.

Syntax:

   handlers => { 'key' => \&function, 'another key' => \&function2 },


I pass a reference to the $session handler as argument one.

As an example, if you wanted f5 to run a "sh ver" on cisco routers you could
do this:

    handlers => { '\[15~' => sub { ${$_[0]}->send("sh ver\r"); return 1; } }

The return 1; is required if you want the session to continue after the
handler is run.  So if you wanted to exit the router on f12 you could return
0;

## port

Router or profile directive to indicate what port to connect on.

## autocmds

Router or profile directive to run commands automatically when logging in.
This is an array reference so it requires the square brackets surrounding the
arguments.

Example:

    'autocmds' => [ 'sh ver', 'sh ip int br' ],


## hostsearch

This is a profile or router directive.

Arguments: routername
Returns: a new routername

Usage: this is just like hostname in that it modifies the name during the
connection stage.  The difference here is that it tries to connect using the
supplied name first, assuming that DNS will be available and such.

If the connection fails it calls your user supplied routine, which can,
depending on how you write it, do a database lookup, a fuzzy match on the
name, or any other modification.

In my case, some of our commercial devices use a prefix of "c-" to designate
them, but we don't always type it when we're making a connection.  So we have
an alias like this:

    'hostsearch' => sub { "c-$_[0]"; }

## password

If a password is blank in the config file then the script will attempt to use
a Keyring for authentication.  It uses the Passwd::Keyring::Auto module for
this if it's installed.  If the password isn't found it will prompt you for it
and store it in the keyring.


# wishlist

1.  Colorized router text, so "show int" errors would show up easily
2.  scrollback buffer across multiple sessions
3.  URI methods on the command line, so you could say telnet://routername or ssh://routername if you wanted to override the method
4.  A testing framework.  How can we simulate login to devices?  Do we ignore that and just modularize the code and test small parts of it?
5.  If it doesn't currently work, handle noenable/no aaa properly

