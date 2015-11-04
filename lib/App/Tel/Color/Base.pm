package App::Tel::Color::Base;

=head1 name

App::Tel::Color::Base - parent stub and examples for Color modules

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

    my $colorobject = new App::Tel::Base;

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
    my ($self, $text) = @_;

    return colored($text, 'cyan');
}

=head2 parse

    $colorobject->parse($buffer, $callback);

Breaks a string up into substrings by line.  It then calls the callback with
the substring.  The callback defaults to $self->colorize();

=cut

sub parse {
    my ($self, $buffer, $cb) = @_;
    my $output = '';

    if (!defined $cb) {
        $cb = sub { my ($self, $val) = @_; $self->colorize($val) };
    }

    while(1) {
        my $string;
        # what about final lines that don't end in \r?  Need to check this..
        if($buffer =~ /^(.*?[\x0d\x0a]{1,2})/s) {
            $string = substr($buffer,0,length $1,'');
        }

        last unless $string;
        $output .= $cb->($self, $string);
    }

    if (length $buffer) {
        $output .= $cb->($self, $buffer);
    }
    return $output;
}

=head2 get_colors

    my @colors = $self->get_colors();
    my $color = $self->get_color(1);

Returns a list of available colors by their names.  This list excludes the RED
color because it's used for errors and these colors are specifically for the
rainbow code that doesn't use red.

If given a value, it returns $color[value].

=cut

sub get_colors {
    $_[1] ? $colors[$_[1]] : @colors;
}

1;
