# -*- perl -*-

use Test::More tests => 8;
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
				    log_args(),
				   ),				"new()";
}

SKIP: {
    skip("No Net::Telnet::Cisco session", 7) unless $S;

    ok $S->login(Name     => $G{LOGIN},
		 Password => $G{PASSWD},
		 Passcode => $G{PASSCODE},),			"login()";

    ok $S->always_waitfor_prompt(1),				"always_waitfor_prompt()";
    ok $S->print("show clock")
	&& $S->waitfor("/not_a_real_prompt/"),			"waitfor() autochecks for prompt()";

    is $S->always_waitfor_prompt(0), 0,				"don't always_waitfor_prompt()";
    ok $S->timeout(3),						"set timeout to 3 seconds";

    eval { $S->print("show clock") && $S->waitfor("/not_a_real_prompt/") };
    ok $S->timed_out,						"waitfor() timedout";
    like $@, "/pattern match timed-out/",				"Got 'pattern match timed-out' error";
}

END {
   cleanup(savelogs => $G{SAVELOGS},
		   failed => scalar grep {$_ == 0} Test::More->builder->summary,
		  );
};
