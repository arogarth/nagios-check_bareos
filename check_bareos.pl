#! /usr/bin/perl -w
#
# See INSTALL document
#

use strict;
use FindBin;
FindBin::again();
use lib $FindBin::Bin;
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use vars qw($PROGNAME $PROGVER);

use Getopt::Long;
use vars qw($opt_V $opt_h $verbose $job);

$PROGNAME = "check_bareos";
$PROGVER = "0.2";

my @okStatus = ('C', 'R', 'T');
my @warningStatus = ('F', 'S', 'm', 'M', 's', 'j', 'c', 'd', 't', 'p', 'i', 'a'); # All Waiting status

# add a directive to exclude buffers:
my $DONT_INCLUDE_BUFFERS = 0;

sub print_help ();
sub print_usage ();
#sub sys_status ();

my $bareosDir = "/etc/bareos";
my $baculaDir = "/etc/bacula";
my $workingDir = "";

if(-d $bareosDir) {
	$workingDir = $bareosDir;
} elsif (-d $baculaDir ) {
	$workingDir = $baculaDir;
} else {
	print "UNKNOWN: CAN'T DETECT BAREOS/BACULA";
	
	exit $ERRORS{'UNKNOWN'};
}

Getopt::Long::Configure('bundling');
GetOptions (
        "V"     => \$opt_V, "version"    => \$opt_V,
        "h"     => \$opt_h, "help"       => \$opt_h,
        "v"     => \$verbose, "verbose"  => \$verbose,
        "j=s"   => \$job, "job=s" => \$job);


if ($opt_V) {
  print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
  exit $ERRORS{'UNKNOWN'};
}

if ($opt_h) {
  print_help();
  exit $ERRORS{'UNKNOWN'};
}

# Command to fetch jobs
my $cmd = "echo \"list job=\\\"${job}\\\"\" | bconsole -c ${workingDir}/nagios-console.conf";

# split jobs by line to array
my @jobs = split('\n', `$cmd`);

my $jobCount = $#jobs;
my @jobRow = ();

# search for last valid job entry from bottom of the table
for(my $i=$#jobs; $i>0; $i--) {
        if($jobs[$i] =~ /^\|\s[0-9]/) {
                @jobRow = split(/\s*\|\s*/, $jobs[$i]);
                last;
        }
}

# No job found? exit with unknown state
if(!@jobRow) {
        print "UNKNWON: JOB NOT FOUND!\n" . join("\n", @jobs);
        exit $ERRORS{'UNKNOWN'};
}

# Field 8 is status-field
my $jobStatus = $jobRow[8];

if( grep{ /$jobStatus/i } @okStatus ) {
        print "OK: " .  join(" / ", @jobRow) . "\n";
        exit $ERRORS{'OK'};
} elsif( grep{ /$jobStatus/i } @warningStatus ) {
		print "WARNING: " .  join(" / ", @jobRow) . "\n";
        exit $ERRORS{'WARNING'};
} else {
        print "CRITICAL: " .  join(" / ", @jobRow) . "\n";
        exit $ERRORS{'CRITICAL'};
}

sub print_usage () {
	print "Usage: $PROGNAME -j <JobName>\n";
	exit $ERRORS{'UNKNOWN'} unless ($opt_h);
}

sub print_help () {
	print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
	print "Copyright (c) 2013 arogarth\n";
	print "\n";
	print_usage();
	print "\n";
	print "-j <JobName> = Bareos/Bacula Job-Name\n";
	print "-h = This screen \n\n";
	support();
}
