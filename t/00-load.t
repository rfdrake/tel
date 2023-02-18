use strict;
use warnings;
use lib qw(lib);
use Test::More;
plan tests => 8;
use_ok('App::Tel');
use_ok('App::Tel::HostRange');
use_ok('App::Tel::Color');
use_ok('App::Tel::Color::Base');
use_ok('App::Tel::Color::Cisco');
use_ok('App::Tel::Color::CiscoPingRainbow');
use_ok('App::Tel::Color::CiscoLog');
use_ok('App::Tel::Macro');
