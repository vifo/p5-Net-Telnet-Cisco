# -*- perl -*-

use Test::More tests => 11;
use Net::Telnet::Cisco;
use FindBin;
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
    skip("No Net::Telnet::Cisco session", 9) unless $S;

    ok $S->login(Name     => $G{LOGIN},
		 Password => $G{PASSWD},
		 Passcode => $G{PASSCODE},),			"login()";

    ok $S->autopage,		       				"autopage() on";
    my @out = $S->cmd('show ver');
    unlike $out[-1], '/--More--/',				"autopage() last line";
    unlike $S->last_prompt, '/--More--/',				"autopage() last prompt";

    my %logs = log_args();
    open LOG, "< $logs{Input_log}" or die "Can't open log: $!";
    my $log = join "", <LOG>;
    close LOG;

    # Remove last prompt, which isn't present in @out
    $log =~ s/\cJ\cJ.*\Z//m;

    # Strip ^Hs from log
    $log = Net::Telnet::Cisco::_normalize($log);
    is my $count = ($log =~ tr/\cH//), 0,			"_normalize()";

    # get rid of "show ver" line and turn @out into a string.
    shift @out;
    my $out = join "", @out;
    $out =~ s/\cJ\cJ.*\Z//m;

    my $i = index $log, $out;
    is $i + length $out, length $log,				"autopage() 1.09 bugfix";

    # Turn off autopaging. We should timeout with a More prompt
    # on the last line.
    is $S->autopage(0), 0,					"autopage() off";

    # Turn off error handling; we *want* to time-out now.
    $S->errmode('return');
    $S->errmsg('');

    show_help($S, -Timeout => 1);
    ok $S->timed_out,						"timed_out()";
    like $S->errmsg, '/timed-out/',				"autopage() not called";
    ok $S->cmd("\b" x 6),				 	"show ? cleanup";

    # Restore error handling
    $S->errmode(\&confess);

    # Cancel out of the "show interfaces"
    $S->cmd("\cZ");

    $S->close;
}

END {
   cleanup(savelogs => $G{SAVELOGS},
		   failed => scalar grep {$_ == 0} Test::More->builder->summary,
		  );
};
