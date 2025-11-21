# xargs error handling can bite you.

If you've ever run a script then realized something isn't quite right you
might hit Ctrl-C to make changes and start again.  If you're running this
through an xargs pipeline you might have issues.

Depending on when you interrupted, what is probably going to happen is this:
The currently running task will exit from the interrupt, but the next task
that was going to run will start running. Control will be returned to you at
the tty, so the process will be in the background.

This is difficult to hunt for in an emergency. You may end up watching your
out of control script reboot dozens of routers.

## Solutions

### Use parallel instead of tel

parallel just handles this better.  Ctrl-C will almost certainly do what you
want.

### Use xargs -e to exit on first error

This should kill the entire pipeline when an error is encountered. This might
not be what you want though, if some of your scripts can error.

## Note about pipelines and STDIN Not a tty

Sometimes you want to run a long pipeline to determine a list of which devices
to login to, and then you want to login to each one and type some commands. If
you reach for xargs you'll get a message that STDIN is not a TTY:

    devi site | grep device_model | a2 | grep -v other_thing | xargs tel
    admin@devicename's password: STDIN Not a tty...

xargs needs to grab STDIN so it can convert the pipeline values into
arguments, and I guess it can't give it back. This is not just xargs, parallel
does the same thing. You can fix this by rearranging the command to not use
a pipeline, but instead use a temporary filehandle:

    xargs -a <(devi site | grep device_model | a2 | grep -v other_thing) tel

You can also remove xargs completely if you get rid of the CR at the end of
each line. It requires you to use tr which may be tougher to remember than
xargs:

    tel $(devi site | grep device_model | a2 | grep -v other_thing | tr '\n' ' ')

# Conclusion

Ok, so maybe none of this is easier to remember. The point is that it's super easy to
remember you can take a pipeline and xargs it into a new command. I've been
running that for years and it's really hard to break the habit, but parallel
is safer.
