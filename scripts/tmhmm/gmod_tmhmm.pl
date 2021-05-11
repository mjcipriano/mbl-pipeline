#!/usr/bin/perl

# This will take as an argument the database name and will then
# as input to stdin will take the results of the tmhmm run and insert the results into the database
# Usage: ./gmod_tmhmm.pl giardia 

use strict;
                                                                                                                                                                                                                                                    
use DBI;
use Mbl;
use Bio::SeqIO;
use Bio::Seq;
use File::Temp qw/ tempfile tempdir/;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh();

my $orfsq = $dbh->prepare("select orfid, sequence from orfs where delete_fg = 'N'");
my $insert_blast_q = $dbh->prepare("insert into blast_results (idname, accession_number, description, algorithm, db, evalue, sequence_type_id, primary_id, query_start, query_end, gi, hit_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
my $insert_blast_full_q = $dbh->prepare("insert into blast_report_full (idname, report, sequence_type_id, db_id, algorithm_id) VALUES (?, ?, ?, ?, ?)");
my $delete_blast_q = $dbh->prepare("delete from blast_results where idname = ? AND sequence_type_id = ? AND db = ? AND algorithm = ?");
my $delete_blast_full_q = $dbh->prepare("delete from blast_report_full where idname = ? AND sequence_type_id = ? AND db_id = ? AND algorithm_id = ?");


my ($temp_fh,$temp_fn) = tempfile();
my $dir = tempdir( CLEANUP => 1);


my $my_orfid = 0;
my $last_orfid = 0;
my $domains;
my $full_report = '';

my $algorithm_id = $mbl->get_algorithm_id(lc('tmhmm'));
my $db_id = $mbl->get_db_id('interpro');
my $seq_type_id = $mbl->get_sequence_type_id('orf');


if(!$db_id || !$algorithm_id || !$seq_type_id )
{
        die ("The database does not have tmhmm as a database type");
}

$orfsq->execute();

while(my $orf_row = $orfsq->fetchrow_hashref)
{
	# Create an inputfile
	my ($orf_fh, $orf_fn) = tempfile();
	my $orf_seqio = Bio::SeqIO->new(-file=>">$orf_fn", -format=>'fasta');
	my $seq = Bio::Seq->new(-id=>$orf_row->{orfid}, -seq=>$orf_row->{sequence});
	$orf_seqio->write_seq($seq->translate);
	#system("cd $dir;/xraid/bioware/linux/TMHMM2.0c/bin/tmhmm $orf_fn > $temp_fn");
	system("cd $dir;tmhmm $orf_fn > $temp_fn");
	open(TMHMM, $temp_fn);
	my $my_orfid = $orf_row->{orfid};
	my $domains;
	my $full_report = '';
	my $num_tmdomains = 0;

	# Delete all for this orf
	$delete_blast_q->execute($my_orfid, $seq_type_id, $db_id, $algorithm_id);
	while(<TMHMM>)
	{
		my $line = $_;


		chomp($line);

		if($line =~ m/^#/)
		{
			# Check if this one tells me how many tmhmm's we have
	
			if($line =~ m/Number of predicted TMHs/)
			{
				($num_tmdomains) = $line =~ /(\d+)$/;
			}
	
		} else
		{
			# Check if this is a new prediction
			if($num_tmdomains > 0)
			{
				my(undef, undef, $loc, $start, $stop) = $line =~ /(\d+)\s+(.+)\s+(\w+)\s+(\d+)\s+(\d+)/;
				# insert the orf
				$insert_blast_q->execute($my_orfid, 'tmhmm', $loc, $algorithm_id, $db_id, undef, $seq_type_id, 'undef', $start, $stop, undef, undef);
				#print join("\t", $my_orfid, 'tmhmm', $loc, $algorithm_id, $db_id, undef, $seq_type_id, 'undef', $start, $stop, undef, undef) . "\n";
			}
		}
	
		$full_report .= $line . "\n";
	
			
	}

	# Insert the full report
	#print "FULL $last_orfid\n" . $full_report . "\n";
	
	$delete_blast_full_q->execute($my_orfid, $seq_type_id, $db_id, $algorithm_id);
	$insert_blast_full_q->execute($my_orfid, $full_report, $seq_type_id, $db_id, $algorithm_id);

	close(TMHMM);
	unlink($orf_fn);
}

unlink($temp_fn);

	
