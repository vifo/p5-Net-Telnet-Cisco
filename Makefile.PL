# -*- perl -*-

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker qw/prompt/;
use Term::ReadKey;
use Cwd;
use Carp;
use t::Utils;

use vars qw/%LOGIN/;
$LOGIN{SAVELOGS} = "n";

# There are two files used to propagate login info:
# ./login.txt and ./tmp.txt.
#
# login.txt is used only for testing. I tire of typing the same login
# info over and over.
#
# tmp.txt is used to hand off the login info collected by Makefile.PL
# to all of the t/*.t tests. This file is written during `perl
# Makefile.PL` deleted after `make test`. It will only be created if
# the project directory has a sufficient level of perms or we can
# set it to 700. This will prevent most snooping attacks.

#------------------------------
# Main
#------------------------------

get_login();
fix_perms();

WriteMakefile(
    'NAME'		=> 'Net::Telnet::Cisco',
    'VERSION_FROM'	=> 'Cisco.pm',
    'PREREQ_PM'		=> { Net::Telnet    => 3.03,
			     Term::ReadKey  => 2,
			     Test::More	    => 0,
			     Cwd	    => 0,
			     FindBin	    => 0,
			     Socket	    => 0,
			     Sys::Hostname  => 0,
			     Carp	    => 0,
			     Config	    => 0,
			     File::Find	    => 0,
			   },
     ($] ge '5.005') ? (
			AUTHOR	  => 'Joshua Keroes (joshua@cpan.org)',
			ABSTRACT  => 'automate Cisco management',
		       ) : (),
);

exit;

#------------------------------
# Subs
#------------------------------

sub get_login {
    if (-r "login.txt") {
	load("login.txt");
	return;
    }

    print <<EOB;

Net::Telnet::Cisco needs to log into a router to perform it\'s full
suite of tests. To log in, we need a test router, a login, a password,
an optional enable password, and an optional SecurID/TACACS PASSCODE.

To skip these tests, hit "return".

EOB

    my $savemsg = "Save logs? (a)lways | (n)ever | only on (f)ailure:";
    {
	$LOGIN{SAVELOGS} = prompt($savemsg, $LOGIN{SAVELOGS});
	unless ($LOGIN{SAVELOGS} =~ /^[anf]/) {
	    warn qq(That\'s not a "a", "n", or "f". Try again.\n);
	    $LOGIN{SAVELOGS} = '';
	    redo;
	}

	# Only want the first character.
	$LOGIN{SAVELOGS} = substr $LOGIN{SAVELOGS}, 0, 1;
     }

    $LOGIN{ROUTER}   = prompt("Router:",   $LOGIN{ROUTER})	or return;
    $LOGIN{LOGIN}    = prompt("Login:",    $LOGIN{LOGIN})	or return;
    $LOGIN{PASSWD}   = passprompt("Password:", $LOGIN{PASSWD}) or return;
    $LOGIN{ENABLE}   = passprompt("Enable password [optional]:", $LOGIN{ENABLE});
    $LOGIN{PASSCODE} = passprompt("SecurID/TACACS PASSCODE [optional]:", $LOGIN{PASSCODE});
}

sub fix_perms {
    fixmode();

    if (-e 'logs') {
	my $d = cwd();
	die "Please remove '$d/logs', it's in the way\n" unless -d _;
    } else {
	mkdir 'logs' or die "Can't create log dir 'logs/': $!";
    }

    fixmode('logs');

    save("tmp.txt" => %LOGIN ) unless -r 'login.txt';
}


# Lifted from ExtUtils::MakeMaker, with minor mods.
#
# If the user has Term::ReadKey, we can hide any passwords
# they type from shoulder-surfing attacks.
#
# Args: "Question for user", "optional default answer"
sub passprompt ($;$) {
    my ($msg, $def) = @_;

    confess( "passprompt($msg, [$def]) called incorrectly" )
	unless defined $msg;

    local $| = 1;

    my $dispdef	 = defined $def ? "[$def] " : " ";
    $def	 = defined $def ? $def     : "";

    print "$msg $dispdef";

    my $ans;
    my $ISA_TTY = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)); # Pipe?

    if ( $ISA_TTY ) {
	if ( $Term::ReadKey::VERSION ) {
	    ReadMode( 'noecho' );
	    chomp( $ans = ReadLine(0) );
	    ReadMode( 'normal' );
	    print "\n";
	} else {
	    chomp( $ans = <STDIN> );
	}
    } else {
        print "$def\n";
    }

    return $ans ne '' ? $ans : $def;
}
