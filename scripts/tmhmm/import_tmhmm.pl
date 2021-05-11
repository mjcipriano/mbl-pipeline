#!/usr/bin/perl

# This will take as an argument the database name and will then
# as input to stdin will take the results of the tmhmm run and insert the results into the database
# Usage: ./import_tmhmm.pl giardia < giardia_results.txt

use strict;
                                                                                                                                                                                                                                                    
use CGI qw(:all);
use CGI::Pretty;
use DBI;
use Mbl;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh();

my $insert_blast_q = $dbh->prepare("insert into blast_results (idname, accession_number, description, algorithm, db, evalue, sequence_type_id, primary_id, query_start, query_end, gi, hit_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
my $insert_blast_full_q = $dbh->prepare("insert into blast_report_full (idname, report, sequence_type_id, db_id, algorithm_id) VALUES (?, ?, ?, ?, ?)");
my $delete_blast_q = $dbh->prepare("delete from blast_results where idname = ? AND sequence_type_id = ? AND db = ? AND algorithm = ?");
my $delete_blast_full_q = $dbh->prepare("delete from blast_report_full where idname = ? AND sequence_type_id = ? AND db_id = ? AND algorithm_id = ?");

my $my_orfid = 0;
my $last_orfid = 0;
my $num_tmdomains = 0;
my $domains;
my $full_report = '';

my $algorithm_id = $mbl->get_algorithm_id(lc('tmhmm'));
my $db_id = $mbl->get_db_id('interpro');
my $seq_type_id = $mbl->get_sequence_type_id('orf');

if(!$db_id || !$algorithm_id || !$seq_type_id )
{
        die ("The database does not have tmhmm as a database type");
}

while(<>)
{
	my $line = $_;


	chomp($line);

	if($line =~ m/^#/)
	{
		# Check if this one tells me how many tmhmm's we have
		($my_orfid) = $line =~ /^#\ (\d+)/;

		if($last_orfid == $my_orfid)
		{
			# Do nothing
		} elsif($my_orfid == 0)
		{
			# Do nothing
		} else
		{
			# Insert the full report
			$delete_blast_full_q->execute($last_orfid, $seq_type_id, $db_id, $algorithm_id);
			$insert_blast_full_q->execute($last_orfid, $full_report, $seq_type_id, $db_id, $algorithm_id);
#			print "FULL $last_orfid\n" . $full_report . "\n";
			# Reset the last_orfid
			$last_orfid = $my_orfid;
			$full_report = '';

			# Delete all for the next orf
			$delete_blast_q->execute($my_orfid, $seq_type_id, $db_id, $algorithm_id);
		}

		if($line =~ m/Number of predicted TMHs/)
		{
			($num_tmdomains) = $line =~ /(\d+)$/;
		}

	} else
	{
		# Check if this is a new prediction
		if($num_tmdomains > 0)
		{
			my($orfid, undef, $loc, $start, $stop) = $line =~ /(\d+)\s+(.+)\s+(\w+)\s+(\d+)\s+(\d+)/;
			# insert the orf
			$insert_blast_q->execute($orfid, 'tmhmm', $loc, $algorithm_id, $db_id, undef, $seq_type_id, 'undef', $start, $stop, undef, undef);
#			print join("\t", $orfid, 'tmhmm', $loc, $algorithm_id, $db_id, undef, $seq_type_id, 'undef', $start, $stop, undef, undef) . "\n";
		}
	}

	$full_report .= $line . "\n";

		
}

# Insert the last full report
#print "FULL $last_orfid\n" . $full_report . "\n";

$delete_blast_full_q->execute($last_orfid, $seq_type_id, $db_id, $algorithm_id);
$insert_blast_full_q->execute($last_orfid, $full_report, $seq_type_id, $db_id, $algorithm_id);

