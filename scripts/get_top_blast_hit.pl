#!/usr/bin/perl

# This script will get print to the screen the top blast hit in tab delimited format of each orf
# Usage: ./get_top_blast_hit.pl giardia > outfile.txt

use strict;
    
# Connect to the database
use Mbl;

my $mbl = Mbl::new(undef, $ARGV[0]);
                                                                                                                                                                                                                                                       
my $dbh = $mbl->dbh();

my $orfsh = $dbh->prepare("select orfid from orfs where delete_fg = 'N'");
 my $top_blasth = $dbh->prepare("select hit_name, description, evalue, accession_number, gi from blast_results where sequence_type_id = 2 AND db IN (2, 3) AND algorithm = 3 AND idname = ? AND evalue < 1e-2 order by evalue limit 1");

$orfsh->execute();

while(my $orf_row = $orfsh->fetchrow_hashref)
{
	$top_blasth->execute($orf_row->{orfid});
	if($top_blasth->rows > 0)
	{
		my $bh = $top_blasth->fetchrow_hashref;
		print join("\t", $orf_row->{orfid}, $bh->{evalue}, $bh->{accession_number}, $bh->{gi}, $bh->{hit_name}, $bh->{description}) . "\n"; 
	} else
	{
		print $orf_row->{orfid} . "\t" . "No Blast Hit\n";
	}
}
