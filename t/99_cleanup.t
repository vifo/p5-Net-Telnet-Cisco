# -*- perl -*-
#
# Not tests, these are cleanup routines.
#

use Test::More tests => 1;
use ExtUtils::MakeMaker;
use File::Path;
use t::Utils;
use Cwd;

my %G;
eval { %G =load() };
if ($@ =~ /Login data not available/) {
    pass "Temp files deleted";
    exit;
}

rm_tmp();
rm_logs();
test_notice();

pass;

exit;

#------------------------------------------------------------
# Subs
#------------------------------------------------------------

sub rm_tmp {
    diag "Deleting tempfiles...";

    if (-e "tmp.txt") {
	if (unlink "tmp.txt") {
	    diag "done.\n"
	} else {
	    diag "Can't delete tmp.txt. Help! $!";
	}
    }
}

sub rm_logs {
    diag "

============================================================
   	      WARNING! WARNING! WARNING!


 $G{LOGDIR}
 contains logs with security information.
 In `perl Makefile.PL` you asked to save them.
 We saved them. Delete them when you see fit.


   	      ALART! BWEEOOOP! ACHTUNG!
============================================================

" if scalar glob <$G{LOGDIR}/*>;
}

sub test_notice {
    diag "
============================================================
   	      WARNING! WARNING! WARNING!


 You are using a persistent login file for testing
 Net::Telnet::Cisco. Your router, login and passwords
 will NOT be deleted automatically!


 Don't forget to remove the data
 when you're done with this command:

 rm $FindBin::Bin/../login.txt


   	      ALART! BWEEOOOP! ACHTUNG!
============================================================
" if -r "login.txt";

}
