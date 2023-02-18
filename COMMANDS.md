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

## sshoptions

Allows you to set cli options for ssh.  Example to turn off host key checking 
(insecure, I do not recommend this for production)

    'sshoptions' => [ 'UserKnownHostsFile=/dev/null', 'StrictHostKeyChecking=no' ]

## ciphertype

Allows overriding the ssh cipher.  Example:

   { 'ciphertype' => '3des' },

## identity

Allows overriding the ssh identity.  Example:

   { 'identity' => "$ENV{HOME}/.ssh/my_router_key" },

## sshflags

For ssh options not covered in the above examples.  This allows you to add any ssh command.

Example:

   { 'sshflags' => '-c 3des -i ~/.ssh/my_router_key' },

## nologin

This is a flag for when you are using ssh identities and don't need to specify a login 
username or password.  Normally this wouldn't be needed, but sometimes the motd/banner has
the word "Login:" in the text so you end up sending the username despite not needing it.

Here is the example that tripped me up:
Last login: Tue Aug 18 07:54:30 2020 from x.x.x.x

   { 'nologin' => 1 },

## hostname

Hostname is a router directive.  It has two uses which are outlined below.

### hostname (aliases)

Sometimes you want to connect to a device with a hostname that isn't in DNS.
Maybe the DNS name is long and you want to abbreviate it, or maybe you want to
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

## syntax

If you want to load a syntax highlight module then you can specify the prefix
here.  For example, DlinkColor.pm would be loaded by

    syntax => 'Dlink',

You can chain load these so you can have a default set of highlight rules for
your company and specific set of rules for Cisco routers or switches or
whatever..

## username_prompt and password_prompt

    username_prompt => "nom d'utilisateur:",
    password_prompt => 'mot de passe:',

You might have a system that has a prompt that isn't like one of the standard
ones used by most vendors.  You might even find systems that have been
regionalized and prompt you in your native language.  If this is the case you
can override the default username and password prompts.

## ena_username_prompt and ena_password_prompt

    ena_username_prompt => "nom d'utilisateur:",
    ena_password_prompt => 'mot de passe:',

Very similar to the normal username prompt.  If your enable prompt has been
changed to something you can override it using these commands.

## pagercmd

    pagercmd => 'disable clipaging',

Extreme networks and Dlink both use 'disable clipaging' while Cisco uses 'term
length 0'.  Juniper uses 'set cli screen-length 0', but also might need 'set
cli complete-on-space off' to avoid annoying you while running scripts.

Some vendors don't have a command to turn off the pager.  In those cases I
tried setting tty rows to 10000.  Not suprisingly, the vendors that I tried it
on don't use the actual terminal size to control paging, so they still had
more prompts every 20 or so lines.

If your particular device does respect tty sizing, and you have the
Term::ReadKey module, then you can set:

    pagercmd => sub { _stty_rows(10000) },

In any case, these pagercmds take effect when tel is run in a non-interactive
mode, using either the -c or -x flags to specify scripts to run.

# Host Ranges

If you have the optional NetAddr::IP module installed you can use ranges in
the 'rtr' array instead of regexes.  Here are some examples:


    # you can use just the trailing octet:
    { 'regex' => '172.28.0.2-28', 'profile' => 'zhone_olt' },
    # or the full IPv4 address:
    { 'regex' => '192.168.13.17-192.168.32.128', 'profile' => 'zhone_olt' },
    # IPv6 is supported:
    { 'regex' => 'fe80::1-fe80::256', 'profile' => 'zhone_olt' },
    # CIDR is also supported:
    { 'regex' => '192.168.13.0/24', 'profile' => 'zhone_olt' },
    { 'regex' => 'fe80::/64', 'profile' => 'zhone_olt' },
    # comma separation is supported if you have multiple values that will load the
    # same profile:
    { 'regex' => '192.168.13.17-192.168.32.128,172.16.0.2-172.16.0.13,172.28.0.0/24', 'profile' => 'zhone_olt' },

This allows you to load profiles by lists of IPs instead of DNS based
hostnames, which can be useful if your devices are spread out and your gear
isn't organized by DNS.


# wishlist

1.  scrollback buffer across multiple sessions

