#!/usr/bin/perl


use strict;
use Bio::SeqIO;
use Mbl;

# This file will take a file of orfs in fasta format and print out their orfid and where they localize using IPSORT's algorithm

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh();

my $signalp_bin = 'signalp -t euk';
my $insert_blast_q = $dbh->prepare("insert into blast_results (idname, accession_number, description, algorithm, db, evalue, sequence_type_id, primary_id, query_start, query_end, gi, hit_name, score) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
my $insert_blast_full_q = $dbh->prepare("insert into blast_report_full (idname, report, sequence_type_id, db_id, algorithm_id) values (?, ?, ?, ?, ?)");

my $in_file = $ARGV[1];

my $orfs = Bio::SeqIO->new('-file'=> $in_file, '-format'=>'Fasta');

my $db_id = $mbl->get_db_id('signalp');
my $seq_type_id = $mbl->get_sequence_type_id('orf');
my $algorithm_id = $mbl->get_algorithm_id('signalp');

if($db_id == undef)
{
	die("No Database Defined");
}

if($seq_type_id == undef)
{
	die("No Sequence Type Defined");
}

if($algorithm_id == undef)
{
	die("No Algorithm Defined");
}
while(my $orf = $orfs->next_seq() )
{
	open(TMP, ">", 'tmp.fasta');
	my ($name) = $orf->display_id =~ /^(\d+)/;

	print TMP '>' . $orf->display_id . "\n" . $orf->seq . "\n";
	close(TMP);

	my $output;
	$output = system("$signalp_bin tmp.fasta > tmp.output");

	open(ANALYSIS, "<", "tmp.output");

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

			print join("\t", $name, $prediction, $pep_prob, $anchor_prob, $cleave_site_prob, $pos_1, $pos_2, $score) . "\n";

			$insert_blast_q->execute($name, 'signalp', $prediction, $algorithm_id, $db_id, undef, $seq_type_id, 'signalp', $pos_1, $pos_2, undef, $prediction, $score);

		}

	}
	$insert_blast_full_q->execute($name, $full_report, $seq_type_id, $db_id, $algorithm_id);

}



