#!/usr/bin/perl

# This file will take a file of orfs in fasta format and print out their orfid and where they localize using IPSORT's algorithm. It will also 
# insert the results into the blast_results table.  ipsort must be in your path for this to work and a license file must be present.
# Input the organism database name and a fasta file of the organism's open reading frames.

# Usage: ./parse_ipsort.pl giardia giardia.fasta

use strict;
use Bio::SeqIO;
use Mbl;


my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh();

my $ipsort_bin = 'ipsort -l /bioware/iPSORT/license/ipsort-license-root -type nonplant -F';
my $insert_blast_q = $dbh->prepare("insert into blast_results (idname, accession_number, description, algorithm, db, evalue, sequence_type_id, primary_id, query_start, query_end, gi, hit_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
 

my $in_file = $ARGV[1];

my $orfs = Bio::SeqIO->new('-file'=> $in_file, '-format'=>'Fasta');

my $db_id = $mbl->get_db_id('ipsort');
my $seq_type_id = $mbl->get_sequence_type_id('orf');
my $algorithm_id = $mbl->get_algorithm_id('ipsort');

while(my $orf = $orfs->next_seq() )
{
	open(TMP, ">", 'tmp.fasta');
	my ($name) = $orf->display_id =~ /^(\d+)/;

	print TMP '>' . $orf->display_id . "\n" . $orf->seq . "\n";
	close(TMP);

	my $output;
	$output = system("$ipsort_bin -i tmp.fasta -o tmp.output");

	open(IPSORT, "<", "tmp.output");

	while(<IPSORT>)
	{
		my $line = $_;

		if($line =~ /^Prediction\:/)
		{
			my $next_line = <IPSORT>;
			my ($type) = $next_line =~ /^\s+(.+)\s+$/;
			print join("\t", $name, $type) . "\n";
			$insert_blast_q->execute($name, 'ipsort', $type, $algorithm_id, $db_id, undef, $seq_type_id, 'ipsort', undef, undef, undef, $type);
		}

	}

}



