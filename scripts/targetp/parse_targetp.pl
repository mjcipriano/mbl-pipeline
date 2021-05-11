#!/usr/bin/perl


use strict;
use Bio::SeqIO;
use Mbl;

# This file will take a file of orfs in fasta format and print out their orfid and where they localize using IPSORT's algorithm
# As well as inserting the results into the database
# Usage: ./parse_targetp.pl giardia giardia_orfs.fasta

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh();

my $signalp_bin = 'targetp -N -s 0.0 -t 0.65 -o 0.52';
my $insert_blast_q = $dbh->prepare("insert into blast_results (idname, accession_number, description, algorithm, db, evalue, sequence_type_id, primary_id, query_start, query_end, gi, hit_name, score) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
my $insert_blast_full_q = $dbh->prepare("insert into blast_report_full (idname, report, sequence_type_id, db_id, algorithm_id) values (?, ?, ?, ?, ?)");

my $in_file = $ARGV[1];

my $orfs = Bio::SeqIO->new('-file'=> $in_file, '-format'=>'Fasta');

my $db_id = $mbl->get_db_id('signalp');
my $seq_type_id = $mbl->get_sequence_type_id('orf');
my $algorithm_id = $mbl->get_algorithm_id('signalp');

while(my $orf = $orfs->next_seq() )
{
	open(TMP, ">", 'tmp.fasta');
	my ($name) = $orf->display_id =~ /^(\d+)/;

	print TMP '>' . $orf->display_id . "\n" . $orf->seq . "\n";
	close(TMP);

	my $output;
	$output = system("$signalp_bin tmp.fasta > tmp.output");

	open(ANALYSIS, "<", "tmp.output");

	my $full_report = '';
	my $score = 0;
	my $header = '';
	my $length = '';
	my $mtp = '';
	my $sp = '';
	my $other = '';
	my $loc = '';
	my $rc = '';

	while(<ANALYSIS>)
	{
		my $line = $_;
		$full_report .= $line;
		
		if($line =~ /^--/)
		{
			$line = <ANALYSIS>;
			$full_report .= $line;
			($header, $length, $mtp, $sp, $other, $loc, $rc) = $line =~ /^(.+)\s+(\d+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+(.+)\s+(\d+)\s*$/;
			chomp($header, $length, $mtp, $sp, $other, $loc, $rc);

			if($loc =~  /\_/)
			{
				$loc = 'other';
			} elsif($loc =~ /\*/)
			{
				$loc = 'undetermined';
			} elsif($loc =~ /\?/)
			{
				$loc = 'undetermined';
			}
			
			my $score = 0;
			if($loc eq 'other')
			{
				$score = $other;
			}elsif($loc eq 'M')
			{
				$score = $mtp;
			} elsif($loc eq 'S')
			{
				$score = $sp;
			} elsif($loc eq 'undetermined')
			{
				$score = 0;
			} else
			{
				$loc = 'undetermined';
				$score = 0;
			}
			
			print join("\t", $name, 'targetp', $loc, $algorithm_id, $db_id, undef, $seq_type_id, 'targetp', undef, undef, undef, $loc, $score) . "\n";
#			$insert_blast_q->execute($name, 'targetp', $loc, $algorithm_id, $db_id, undef, $seq_type_id, 'targetp', undef, undef, undef, $loc, $score);
			while(<ANALYSIS>)
       			{ 		
				$full_report .= $_;
			}
		}

	}

print $full_report . "\n\n";
#	$insert_blast_full_q->execute($name, $full_report, $seq_type_id, $db_id, $algorithm_id);

}



