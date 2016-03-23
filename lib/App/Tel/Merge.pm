package App::Tel::Merge;

use strict;
use warnings;

require Exporter;
our @ISA = qw/ Exporter /;
our @EXPORT_OK = qw/ merge /;

# This was stoled from Hash::Merge::Simple, which stoled from Catalyst::Utils
# I stole it because I wanted to get rid of the dependancy on Clone which
# needs to be compiled by cpanm when we weren't using it.

sub merge (@);
sub merge (@) {
    shift unless ref $_[0]; # Take care of the case we're called like Hash::Merge::Simple->merge(...)
    my ($left, @right) = @_;

    return $left unless @right;

    return merge($left, merge(@right)) if @right > 1;

    my ($right) = @right;

    my %merge = %$left;

    for my $key (keys %$right) {

        my ($hr, $hl) = map { ref $_->{$key} eq 'HASH' } $right, $left;

        if ($hr and $hl){
            $merge{$key} = merge($left->{$key}, $right->{$key});
        }
        else {
            $merge{$key} = $right->{$key};
        }
    }
    return \%merge;
}

