# Password Keyring/Keepass support has been removed

Instead of having individual plugins to support different password storage
mechanisms, we allow the use of environment variables in telrc.

    'default' => {
        'user' => $ENV{'USER'},
        'password' => $ENV{'ROUTER_PASSWORD'},
    },


There are several reasons for this.

1.  We don't need to support 5-6 different password managers or keyrings.
Lots of dead or very underused code can be removed.

Daisy chained keyring/password managers can be done by the invocation command.
So if you want to say pull the password from bitwarden, but pull the bitwarden
master key from keyring, you can do that with external applications.

2.  Caching passwords could not be done in the old design.

If you need to login to routers 100 times a day and your password is protected
with gpg then every time you login the password would need to be decrypted.
If the environment variable is defined when you login then it stays around
until your session is over.


# Drawbacks

Environment variables aren't secure in a multi-user environment.  If someone
has root then they can see everyones unencrypted password in the environment
variables.


# Example

An Example (bitwarden) which shares the password between sessions.  Add this
to your .bashrc file (edit it as needed to work with your password manager,
and the name of your stored password)

if [[ -f /run/shm/$USER-telrc_password_env ]]; then
    export ROUTER_PASSWORD=$(cat /run/shm/$USER-telrc_password_env)
else
    export ROUTER_PASSWORD=$(bw get password "My Router")
    # I'm using mktemp here for file permission reasons
    FILE=$(mktemp --tmpdir=/run/shm)
    echo "$ROUTER_PASSWORD" > $FILE
    ln -si $FILE /run/shm/$USER-telrc_password_env
    trap "rm $FILE /run/shm/$USER-telrc_password_env" EXIT
fi

