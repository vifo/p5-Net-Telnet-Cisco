# -*- perl -*-

#use Test::More qw/no_plan/;
use Test::More tests => 17;

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
				     Timeout => 3,
				    log_args(),
				   ),				"new()";
}

SKIP: {
    skip("No Net::Telnet::Cisco session", 11) unless $S;

    ok $S->login(Name     => $G{LOGIN},
		 Password => $G{PASSWD},
		 Passcode => $G{PASSCODE},),			"login()";

    @help = show_help($S);
    ok @help,							"cmd()";
    ok $S->cmd("\b" x 6),				 	"show ? cleanup";

    $donttouch = 'virgin';
    ok $S->errmode( sub { $donttouch = 'hussy'} ),		"errmode closure";
    is $donttouch, 'virgin',					"errmode shouldn't eval CODE";

    # breaks
    my $errmsg = '';
    sub handler {
	$errmsg = $S->errmsg;
	$S->timed_out(0); 
	$S->timeout(10);
	$S->ios_break;
    }
    ok $S->errmode( \&handler ),	 			"set errmode(errmode())";

    # Turn off autopaging. This will display a more prompt, thus pausing until we timeout.
    is $S->autopage(0), 0,					"turn off autopage";

    $S->timeout(10);

    local $SIG{'__DIE__'} = \&confess;
    @short = show_help($S);

    like $errmsg, "/timed-out/",				"error reports a timeout";
    ok @short <= @help,						"ios_break()";

    # XXX search log for "\cZ"

    is $S->autopage(1), 1, 					"turn on autopage";
    ok $S->cmd("\b" x 6),				 	"show ? cleanup";

    # Error handling
    my $seen = 0;
    ok $S->timeout(3),						"set timeout(1)";

    sub incr { $seen++ }

    ok $S->errmode(\&incr),	 				"set errmode(closure)";
    $S->cmd(  "Small_Change_got_rained_on_with_his_own_thirty_eight"
	    . "_And_nobody_flinched_down_by_the_arcade");

    # $seen should be incrememnted to 1.
    is $seen, 1,						"error() called";

    # $seen should not be incremented (it should remain 1)
    ok $S->errmode('return'),					"no errmode()";
    $S->cmd(  "Brother_my_cup_is_empty_"
	    . "And_I_havent_got_a_penny_"
	    . "For_to_buy_no_more_whiskey_"
	    . "I_have_to_go_home");
    is $seen, 1,						"don't call error()";
}

END {
   cleanup(savelogs => $G{SAVELOGS},
		   failed => scalar grep {$_ == 0} Test::More->builder->summary,
		  );
};
