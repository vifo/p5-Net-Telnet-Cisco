# -*- perl -*-

use Test::More tests => 8;
use Net::Telnet::Cisco;
use Carp;
use t::Utils;

my %G = load();
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
    skip("No Net::Telnet::Cisco session", 5) unless $S;

    ok $S->login(Name     => $G{LOGIN},
		 Password => $G{PASSWD},
		 Passcode => $G{PASSCODE},),		"login()";

    ok $S->cmd('show clock'),				 "cmd() short";
    ok $S->cmd('show ver'),				 "cmd() medium";
    ok show_help($S),					 "cmd() long";
    ok $S->cmd("\b" x 6),				 "show ? cleanup";
    ok @out = $S->cmd(''),				 "cmd() empty";
    is_deeply \@out, [''],				 "...returned array w/ empty string";
}

END {
   cleanup(savelogs => $G{SAVELOGS},
		   failed => scalar grep {$_ == 0} Test::More->builder->summary,
		  );
};
