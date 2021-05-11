#!/usr/bin/perl -w

#########################################
#
# update_dbs.pl - this script takes a file of sql commands and adds them to
#                     each database in jbpcdb, or to a list of datasets
#
# Usage:  update_dbs.pl <sql sourcefile> <optional: database list file>
#
# Author: Susan Huse, shuse@mbl.edu  
# Date: 
# 
# Assumptions: 
#
# Revisions:
#
# Programming Notes:
#
########################################

use strict;
use Mbl;
#use Bio::Seq;
#use Bio::SeqIO;


my $sqlFilename;
my $datasetsFilename;
my $argNum = 1;
my $optionalArgNum = 2;


#######################################
#
# Set up usage statement
#
#######################################
my $usage = " Usage:  update_dbs.pl <sql sourcefile> <optional: database list file>\n"; 
my $scripthelp = qq /
 update_dbs.pl - runs a file of sql commands on each database in jbpcdb,
                     or to a list of datasets.\n
/;


#######################################
#
# Parse commandline arguments, ARGV
#
#######################################

if (scalar @ARGV < $argNum) 
{
	print $scripthelp;
	print "$usage\n";
	exit;
} elsif (($ARGV[0] =~ /help/) || ($ARGV[0] =~ /-h/)) {
	print $scripthelp;
	print "$usage\n";
	exit;
} elsif (scalar @ARGV > $optionalArgNum) {
	print "Incorrect number of arguments.\n";
	print "$usage\n";
	exit;
} else {
	#Test validity of commandline arguments
	$sqlFilename = $ARGV[0];
	if (! -f $sqlFilename) {
		print "Unable to locate input sql file: $sqlFilename.\n";
		exit;
	}
	if ($ARGV[1]) {
		$datasetsFilename = $ARGV[1];
		if (! -f $datasetsFilename) {
			print "Unable to locate input datasets file: $datasetsFilename.\n";
			exit;
		}
	}
}

#######################################
#
# Get the list of sql commands to run
#
#######################################

my @sqlcommands;
open (SQLFILE, "<$sqlFilename") || die "Unable to open $sqlFilename for reading.  Exiting.\n\n";
while (my $line = <SQLFILE>)
{
	chomp $line;
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	if (($line) && ($line !~ /^#/))
	{
		push (@sqlcommands, $line);
	}
}
close (SQLFILE);


#############################################################
#
# Get the list of datasets to update
#
#############################################################

my $mbl = Mbl::new(undef, 'gmoddb');

my @dbs;
if ($datasetsFilename)  #read the dataset list from ARGV[1]
{
	open (DATASETSFILE, "<$datasetsFilename") || die "Unable to open $datasetsFilename for reading.  Exiting.\n\n";
	while (my $line = <DATASETSFILE>)
	{
		chomp $line;
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		if (($line) && ($line !~ /^#/))
		{
			push (@dbs, $line);
		}
	}
	close (DATASETSFILE);
} else { #run on all datasets in gmoddb
	my $shared_dbh = $mbl->shared_dbh;
	my $db_list_h = $shared_dbh->prepare("select id, database_name, project_name, access_type, project_type from gmodweb_databases order by database_name");
	$db_list_h->execute();

	while(my $dbrow = $db_list_h->fetchrow_hashref)
	{
		push (@dbs, $dbrow->{database_name});
	}
}

if (scalar @dbs < 1) 
{
	print "No datasets found.  Exiting.\n\n";
	exit 1;
}

#foreach my $s (@sqlcommands) {print "$s\n";}
#foreach my $d (@dbs) {print "$d\n";}
#exit;

#############################################################
#
# For each dataset, execute the sql commands
#
#############################################################

foreach my $db (@dbs)
{
	print "updating $db\n";

	# Connect to database
	my $cur_mbl = Mbl::new(undef, $db);
	if (! $cur_mbl) {next;}

	my $cur_dbh = $cur_mbl->dbh();
	if(! $cur_dbh)
	{
		print "\tDataset $db not found.\n";
		next;
	}

	# Run each sql command
	foreach my $command (@sqlcommands)
	{
		my $command_h = $cur_dbh->prepare($command);
		$command_h->execute();
	}
}
