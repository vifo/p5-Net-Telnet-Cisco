# -*- perl -*-
#
# Utils.pm - Tools for Tests!
#
# Exports some globals and provides Helpful Subs
#
# jkeroes $Id$

package main;

use File::Basename;
use Test::More;
use FindBin	qw/$Bin/;
use File::Path  qw/mkpath/;

use Cwd;

# Defaults
$LOGDIR = "$Bin/../logs";	# Only valid for files in t/*.t
$SAVELOGS = 'n';

sub fatal (@;);

#------------------------------------------------------------
# Subs
#------------------------------------------------------------

# Runs the 'show ?' command
sub show_help {
    my $session = shift;

    # The prompt will look something like:
    #
    #   "gw01.phnx#show "
    #
    my $prompt = $session->prompt;
    $prompt =~ s{\$\)/$}{\)/};

    # could play wantarray games here but... whatever.
    my @out = $session->cmd(Ors => '',
		  String => 'show ?',
		  Prompt => $prompt,
		  @_,
		 );

    return @out;
}


# Ensure the argument (or current directory if called without args)
# is mode 0700.
sub fixmode {
    my $dir = shift || cwd();

    my $mode = (stat $dir)[2];
    chmod 0700, $dir or fatal <<EOB;

 ============================================================
 Directory '$dir' has an insufficient level of
 permissions to continue. We need 0700. Please
 correct this manually and try again.
 ------------------------------------------------------------

EOB

}

# Loads TSV from a file. Returns a hash
sub load {
    my $file = shift ||	(-r 'tmp.txt' ? 'tmp.txt' :
			 -r 'login.txt' ? 'login.txt' :
			 '');

    my %h = ( SAVELOGS => $SAVELOGS, LOGDIR => $LOGDIR );
    fatal "No login data. Run `perl Makefile.PL` again.\n" unless $file;

    open FH, "< $file" or return %h;
    while (<FH>) {
	next if /^\s*\#/; # skip comments
	chomp;
	my ($k, $v) = split;
	
	$h{$k} = $v;
    }
    close FH or warn $!;

    return %h;
}

# Accepts: $filename, %hash
# Saves to a TSV file.
sub save {
    my $file  = shift || "tmp.txt";

    print "Saving login info to '$file'... ";

    open FH, "> $file" or fatal "Can't open '$file' for write: $!";
    chmod 0700, $file or fatal "Can't set '$file to 0700: $!";

    my %h = @_;
    while (my ($k, $v) = each %h) {
	print FH "$k\t$v\n";
    }

    close FH or warn $!;

    print "done.\n";
}

# Returns logging args for N::T::C->new()
sub log_args {
    my $progname = basename(shift || $0);
    $progname =~ s/\.t$//;

    return ( Input_log	 => "$LOGDIR/$progname.input",
	     Dump_log	 => "$LOGDIR/$progname.dump",
	     Output_log	 => "$LOGDIR/$progname.output",
	   );
}

# Remove logs.
#
# The user was queried in MakeMaker.PL whether he wanted to deleted logs:
#  (A)lways
#  (N)ever
#  only on (F)ailure
#
# We default to Always because things are more secure that way.
#
# Usage:
# cleanup( savelogs => a | n | f,
#	  failed => integer
#	);
sub cleanup {
    my %args = (savelogs => $SAVELOGS, failed => 0, @_, );

    $args{savelogs}  = defined $args{savelogs}	? $args{savelogs}  : $SAVELOGS;
    $args{failed}    = defined $args{failed}	? $args{failed}	   : 0;

    my $progname = basename($0);
    $progname =~ s/\.t$//;

    if (   $args{savelogs} eq 'n'
	|| $args{savelogs} eq 'f' && ! $args{failed}) {
	my @goners = <$LOGDIR/$progname.*>;
	my $cnt = unlink @goners;
	warn "Problems deleting @goners: $!" unless scalar @goners == $cnt;
	diag "Logs deleted." if $ENV{TEST_VERBOSE};
    } else {
	diag "Logs saved.";
    }
}

sub fatal (@;) { Test::More->builder->BAILOUT(@_) }

1;
