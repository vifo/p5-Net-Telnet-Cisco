# -*- perl -*-

use Test::More tests => 2;

BEGIN { use_ok('Net::Telnet::Cisco') }

ok($Net::Telnet::Cisco::VERSION, 	"\$VERSION set");
