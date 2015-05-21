package App::Tel::HostRange;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw ( check_hostrange );
my $_have_netaddr=0;

BEGIN {
    if (eval { require NetAddr::IP; }) {
        NetAddr::IP->import();
        $_have_netaddr=1;
    }
}

=head1 NAME

App::Tel::HostRange - Support for HostRanges

=head1 VERSION

0.2015_01

=cut

our $VERSION = eval  { 0.2015_01 };


=head1 SYNOPSIS

    if (check_hostrange($_, $host));

Searches an IPv4 or IPv6 range to see if it contains a particular IP address.
Returns true if the host is contained in the range, false if it is not.

=head1 AUTHOR

Robert Drake, C<< <rdrake at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2015 Robert Drake, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

=head2 check_hostrange

    if (check_hostrange($rangelist, $host));

Searches an IPv4 or IPv6 range to see if it contains a particular IP address.
Returns true if the host is contained in the range, false if it is not.

This does no validation, leaving it all up to NetAddr:IP and the calling
function.

This should support the following types of ranges:

# 192.168.13.17-192.168.32.128
# 192.168.13.17-22
# fe80::1-fe80::256
# 192.168.13.0/24
# fe80::/64
# 192.168.13.17-192.168.32.128,172.16.0.2-172.16.0.13,172.28.0.0/24

=cut

sub check_hostrange {
    my ($rangelist, $host) = @_;
    return 0 if (!$_have_netaddr);
    $host = NetAddr::IP->new($host) || return 0;

    for(split(/,/,$rangelist)) {
        # if it's a cidr pass it into NetAddr::IP directly
        if ($_ =~ qr#/#) {
            my $range = NetAddr::IP->new($_) || return 0;
            return 1 if ($range->contains($host));
        } else {
            my ($host1, $host2) = split(/-/);
            $host1 = NetAddr::IP->new($host1) || return 0;
            # if they only supplied the last octet
            if ($host2 =~ /^[\da-f]+$/i) {
                my $tmp = $host1->addr;
                # drop the last octet
                $tmp =~ s/([:\.])[\da-f]+$/$1/;
                $host2 = $tmp . $host2;
            }
            $host2 = NetAddr::IP->new($host2) || return 0;
            return 1 if ($host >= $host1 && $host <= $host2);
        }
    }
    return 0;
}

1;
