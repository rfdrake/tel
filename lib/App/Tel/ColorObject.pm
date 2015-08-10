package App::Tel::ColorObject;

=head1 name

App::Tel::ColorObject - parent stub and examples for Color modules

=cut

use Term::ANSIColor;
use strict;
use warnings;

our $VERSION = '0.2';

$Term::ANSIColor::AUTORESET++;         # reset color after each print
$SIG{INT} = sub { print "\n"; exit; }; # reset color after Ctrl-C

our @colors = qw ( GREEN YELLOW BLUE MAGENTA CYAN WHITE );

# Bright colors were added after Term::ANSIColor 3.00
if ($Term::ANSIColor::VERSION >= 3.00) {
    push(@colors, qw (
      BRIGHT_GREEN    BRIGHT_YELLOW
      BRIGHT_BLUE     BRIGHT_MAGENTA    BRIGHT_CYAN     BRIGHT_WHITE
    ));
}



=head1 METHODS

=head2 new

    my $colorobject = new App::Tel::ColorObject;

Initializes a new colorobject.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return bless( { }, $class);
}

=head2 colorize

    $colorobject->colorize('text');

Normally this will consume text from an input buffer and have some logic that
determines how it will color the output.  This method is designed to be
overridden in all child modules.

=cut


sub colorize {
    my $self = shift;
    $_ = shift;

    return colored($_, 'cyan');
}

1;
