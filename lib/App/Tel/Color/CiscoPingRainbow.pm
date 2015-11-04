package App::Tel::Color::CiscoPingRainbow;
use parent 'App::Tel::Color::Base';
use Term::ANSIColor;
use strict;
use warnings;

=head2 new

    my $color = App::Tel::Color::CiscoPingRainbow->new;

New color object..

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless( {
        'current_color' => 0,
        'ping' => 0,
    }, $class);

    $self->{'color_count'} = scalar $self->get_colors();
    return $self;
}

sub _next_color {
    my $self = shift;
    return colored(@_, $self->get_colors($self->{current_color}++ % $self->{color_count}));
}

=head2 colorize

    my $output = $self->colorize($input);

Given a line of text from a cisco router, this will try to colorize it.

=cut


sub colorize {
    my ($self, $text) = @_;

    # We need to define a start point in the buffer that the dot regex isn't
    # allowed to search before so that this line and ones before it with
    # dots don't get red dots.
    if ($text =~ /Sending \d+, \d+-byte ICMP Echos to/) {
        $self->{ping}=1;
    } elsif ($self->{ping}) {
            $text =~ s/(\!)/$self->_next_color($1)/eg;
            $text =~ s/(\.)/colored('.', 'red')/eg;
        if ($text =~ /Success rate is/) {
            $self->{ping}=0;
            $self->{current_color}=0;
        }
    }
    return $text;
}

1;
