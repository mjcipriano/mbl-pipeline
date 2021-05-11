#!/usr/bin/perl -w

use strict;
use Bio::SeqIO;
use File::Temp qw/ tempfile tempdir/;
use Mbl;

# This file will take a file of orfs in fasta format and print out their orfid and where they localize using IPSORT's algorithm

# Set up Mbl and database connection
my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh();

my $signalp_bin = 'signalp -t euk';

# Set up sql queries
my $orfsq = $dbh->prepare("select orfid, sequence from orfs where delete_fg = 'N'");
my $insert_blast_q = $dbh->prepare("insert into blast_results (idname, accession_number, description, algorithm, db, evalue, sequence_type_id, primary_id, query_start, query_end, gi, hit_name, score) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
my $insert_blast_full_q = $dbh->prepare("insert into blast_report_full (idname, report, sequence_type_id, db_id, algorithm_id) values (?, ?, ?, ?, ?)");
my $delete_blast_q = $dbh->prepare("delete from blast_results where idname = ? AND sequence_type_id = ? AND db = ? AND algorithm = ?");
my $delete_blast_full_q = $dbh->prepare("delete from blast_report_full where idname = ? AND sequence_type_id = ? AND db_id = ? AND algorithm_id = ?");

my $db_id = $mbl->get_db_id('signalp');
my $seq_type_id = $mbl->get_sequence_type_id('orf');
my $algorithm_id = $mbl->get_algorithm_id('signalp');

#Test to see if the database has signalp and orf data to use
if(!defined($db_id))
{
	die("No Database Defined");
}

if(!defined($seq_type_id))
{
	die("No Sequence Type Defined");
}

if(!defined($algorithm_id))
{
	die("No Algorithm Defined");
}


# Set up temp directory and create orf files
my ($temp_fh,$temp_fn) = tempfile();
my $dir = tempdir( CLEANUP => 1);

#For each orf in the database
$orfsq->execute();
while(my $orf_row = $orfsq->fetchrow_hashref) 
{
	# Create a temp file of the translated orf
	my ($orf_fh, $orf_fn) = tempfile();
	my $orf_seqio = Bio::SeqIO->new(-file=>">$orf_fn", -format=>'fasta');
	my $seq = Bio::Seq->new(-id=>$orf_row->{orfid}, -seq=>$orf_row->{sequence});
	$orf_seqio->write_seq($seq->translate);

	my $output;
	$output = system("cd $dir; $signalp_bin $orf_fn > $temp_fn");
	open(ANALYSIS, "<", $temp_fn);

	# Delete all for this orf
	my $my_orfid = $orf_row->{orfid};
	$delete_blast_q->execute($my_orfid, $seq_type_id, $db_id, $algorithm_id);

	my $prediction = '';
	my $pep_prob = 0;
	my $anchor_prob = 0;
	my $cleave_site_prob = 0;
	my $pos_1 = 0;
	my $pos_2 = 0;
	my $full_report = '';
	my $score = 0;

	while(<ANALYSIS>)
	{
		my $line = $_;
		$full_report .= $line;
		
		if($line =~ /^Prediction\:/)
		{
			($prediction) = $line =~ /^Prediction\: (.+)/;
			chomp($prediction);
		} elsif($line =~ /^Signal peptide probability/)
		{
			($pep_prob) = $line =~ /^Signal peptide probability\: (.+)/;
			chomp($pep_prob);
		} elsif($line =~ /^Signal anchor probability/)
		{
			($anchor_prob) = $line =~ /^Signal anchor probability\: (.+)/;
			chomp($anchor_prob);
		} elsif($line =~ /^Max cleavage site/)
		{
			($cleave_site_prob, $pos_1, $pos_2) = $line =~ /^Max cleavage site probability\: (.+) between pos\. (.+) and (.+)/;
			chomp($cleave_site_prob, $pos_1, $pos_2);
			if($prediction eq 'Signal peptide')
			{
				$score = $pep_prob;
			} elsif($prediction eq 'Signal anchor')
			{
				$score = $anchor_prob;
			} else
			{
				$score = 0;
			}

			print join("\t", $my_orfid, $prediction, $pep_prob, $anchor_prob, $cleave_site_prob, $pos_1, $pos_2, $score) . "\n";

			$insert_blast_q->execute($my_orfid, 'signalp', $prediction, $algorithm_id, $db_id, undef, $seq_type_id, 'signalp', $pos_1, $pos_2, undef, $prediction, $score);

		}
	}
	$insert_blast_full_q->execute($my_orfid, $full_report, $seq_type_id, $db_id, $algorithm_id);
	unlink($orf_fn);
}

unlink($temp_fn);



