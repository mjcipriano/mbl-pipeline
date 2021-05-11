#!/usr/bin/perl

# This script will fix the web links on pfam reports that get stored in the blast_report_full table to the correct links
# Usage: ./fix_pfam_links.pl giardia

use strict;
                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                       
use Mbl;
use CGI qw(:all);
use CGI::Pretty;
use DBI;
use Bio::Seq;
                                                                                                                                                                                                                                                       
my $mbl = Mbl::new(undef, $ARGV[0]);
                                                                                                                                                                                                                                                       
my $dbh = $mbl->dbh();
                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                       
my $sth = $dbh->prepare("select idname, report, sequence_type_id, db_id, algorithm_id from blast_report_full where db_id = 4 AND algorithm_id = 4 AND sequence_type_id = 2");
                                                                                                                                                                                                                                                       
my $update = $dbh->prepare("update blast_report_full set report = ? where idname = ? AND db_id = 4 AND algorithm_id = 4 AND sequence_type_id = 2");
                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                       
$sth->execute();
                                                                                                                                                                                                                                                       
while(my $row = $sth->fetchrow_hashref)
{
	my $report = $row->{report};
                                                                                                                                                                                                                                                       
	$report =~ s/www\.ncbi\.nlm\.nih\.gov\/entrez\/query\.fcgi\?db=nucleotide&cmd=search&term/pfam\.wustl\.edu\/cgi-bin\/getdesc\?name/gi;

	$update->execute($report, $row->{idname});
}

