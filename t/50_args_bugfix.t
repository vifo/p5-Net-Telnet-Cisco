# -*- perl -*-

use Test::More tests => 2;
use Net::Telnet::Cisco;
use FindBin;
use Carp;
use t::Utils;

my %G =load();
my $S;

SKIP: {
    skip("Router unknown", 1) 		unless $G{ROUTER};
    skip("Login or password unknown", 1)	unless $G{LOGIN} || $G{PASSWD};

    ok $S = Net::Telnet::Cisco->new( Errmode	 => \&confess,
				     Host	 => $G{ROUTER},
				     Prompt       => "/broken_pre1.08/",
				    log_args(),
				   ),				"new()";

    is $S->prompt, '/broken_pre1.08/',				"new(args) 1.08 bugfix";
}

END {
   cleanup(savelogs => $G{SAVELOGS},
		   failed => scalar grep {$_ == 0} Test::More->builder->summary,
		  );
};
