# -*- perl -*-

use Test::More tests => 6;
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
    skip("No Net::Telnet::Cisco session", 5) unless $S;
    skip("Won't enter enabled mode without an enable password", 5)
	unless $G{ENABLE};

    ok $S->login(Name     => $G{LOGIN},
		 Password => $G{PASSWD},
		 Passcode => $G{PASSCODE},),			"login()";

    ok $S->disable,						"disable()";
    ok $S->enable($G{ENABLE}),					"enable()";
    ok $S->is_enabled,						"is_enabled()";

    eval { $S->enable(Level => undef) };
    like $@, 'Level was passed an undef',				"enable() -Level bugfix";

}

END {
   cleanup(savelogs => $G{SAVELOGS},
		   failed => scalar grep {$_ == 0} Test::More->builder->summary,
		  );
};
