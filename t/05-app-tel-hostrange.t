#!/usr/bin/env perl
use lib qw(lib);
use Test::More;
eval 'use NetAddr::IP; 1' or plan skip_all => 'Optional module NetAddr::IP required';

use App::Tel::HostRange qw ( check_hostrange );

# 192.168.13.17-192.168.32.128
# fe80::1-fe80::256
# 192.168.13.0/24
# fe80::/64
# 192.168.13.17-192.168.32.128,172.16.0.2-172.16.0.13,172.28.0.0/24

is(check_hostrange('192.168.13.17-192.168.32.128,172.16.0.2-172.16.0.13,172.28.0.0/24', '192.168.13.16'), 0, 'Host out of range');
is(check_hostrange('192.168.13.17-192.168.32.128,172.16.0.2-172.16.0.13,172.28.0.0/24', '192.168.13.17'), 1, 'Host at edge of range');
is(check_hostrange('fe80::/64','192.168.13.16'), 0, 'IPv6 cidr, IPv4 host -- fail');
is(check_hostrange('fe80::/64','fe80::1'), 1, 'IPv6 cidr');
is(check_hostrange('fe80::/64','2607:f1e8::1'), 0, 'IPv6 cidr, incorrect range host fail');
is(check_hostrange('fe80::1-fe80::256','2607:f1e8::1'), 0, 'IPv6 range, incorrect host fail');
is(check_hostrange('fe80::1-fe80::256','fe80::1'), 1, 'IPv6 range, success');
is(check_hostrange('192.168.13.17-192.168.13.17','192.168.13.16'), 0, 'ipv4 range fail');
is(check_hostrange('192.168.13.17-192.168.13.17','192.168.13.17'), 1, 'ipv4 range success');
is(check_hostrange('192.168.13.17-192.168.13.17','192.168.13.18'), 0, 'ipv4 range fail');
is(check_hostrange('fe80::1/128,fe80::2/128,192.168.13.17-192.168.13.128','192.168.13.18'), 1, 'mixed ipv4/ipv6 range cidr success');
is(check_hostrange('fe80::1/128,fe80::2/128,192.168.13.17-192.168.13.128','192.168.13.1'), 0, 'mixed range/cidr fail');
is(check_hostrange('fe80::1/128,fe80::2/128,192.168.13.17-192.168.13.128','fe80::1'), 1, 'mixed range/cidr success');
is(check_hostrange('fe80::1/128,fe80::2/128,192.168.13.17-192.168.13.128','fe80::2'), 1, 'mixed range/cidr success');
is(check_hostrange('fe80::1/128,fe80::2/128,192.168.13.17-192.168.13.128','fe80::3'), 0, 'mixed range/cidr fail');



done_testing();