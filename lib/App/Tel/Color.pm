package App::Tel::Color;

use strict;
use warnings;
use Carp;
use Module::Load;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw ( load_syntax );

=head1 NAME

App::Tel::Color - Methods for managing App::Tel::Color:: modules

=cut

=head2 load_syntax

    $self->load_syntax('Cisco');

This attempts to load syntax highlighting modules.  In the above example,
Cisco would append Colors to the end and get CiscoColors.pm.  If it can't find
the module it just won't load it.

Returns an arrayref of module references.

Multiple files can be chain loaded by using plus:

    $self->load_syntax('Default+Cisco');

=cut

sub load_syntax {
    my ($self, $list, $debug) = @_;
    return $self if (!defined $list);
    my @syntax;
    push(@syntax, $list);
    if (ref($list) eq 'ARRAY') {
        @syntax = @$list;
    }

    foreach my $l (@syntax) {
        for(split(/\+/, $l)) {

            my $module = "App::Tel::Color::$_";
            next if defined($self->{colors}->{$module});

            eval {
                Module::Load::load $module;
                $self->{colors}->{$module}=$module->new;
            };
            if ($@) {
                carp $@ if ($debug);
            }
        }
    }

    return $self;
}

=head2 new

    my $colors = App::Tel::Color->new;

Initializes a color library.  You can load syntax parsers by calling
load_syntax.

=cut

sub new {
    bless( {
        colors => {},
    }, shift);
}

=head2 colorize

    my $output = $self->colorize($input);

Calls the parser routine for all the loaded syntax modules.

=cut

sub colorize {
    my ($self, $input) = @_;
    while (my ($name, $mod) = each %{$self->{colors}}) {
        $input = $mod->parse($input);
    }
    return $input;
}

1;
