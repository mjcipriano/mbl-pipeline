#!/usr/bin/perl


# This script is used to find areas where intergenic orf hits match orfs within a set ($search_length) distance around that orf.  This can be used to find areas where there is possibly an intron
# or areas where an orf can be extended due to sequencing error or alternate start sites

use strict;

use Mbl;
use Bio::Seq;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;

my $orflisth = $dbh->prepare("select orfid, contig, start, stop, direction, sequence from orfs where delete_fg = 'N'");

my $checkblastq = "select idname, score, accession_number, gi, id, hit_start, query_start, query_end, hit_end, hit_name, query_string, hit_string from blast_results where sequence_type_id = 3 and evalue < 1 AND (description not like '%ATCC 50803%' OR description like '%gb|%') AND idname like ";


my $gettoporfhith = $dbh->prepare("select idname, gi, evalue, hit_name, accession_number, description, query_string, hit_string from blast_results where idname = ? AND evalue < 1 AND db = 2 AND (description not like '%ATCC 50803%' OR description like '%gb|%') order by evalue limit 1");

my $search_length = 500;

$orflisth->execute;
my $id = 1;

while(my $orfrow = $orflisth->fetchrow_hashref)
{
#	print "Starting with orf " . $orfrow->{orfid} . "\n";
	$gettoporfhith->execute($orfrow->{orfid});
	if($gettoporfhith->rows > 0)
	{
		my $tophit = $gettoporfhith->fetchrow_hashref;
		
		# Now find if there are any intergenic orf hits within x basepairs of this orf;
		
		# Find all intergenic sites on this contig;
		my $intergene_h = $dbh->prepare($checkblastq . '"' . $orfrow->{contig} . '%" AND gi = ' . $tophit->{gi});
		$intergene_h->execute();
		if($intergene_h->rows > 0)
		{
#			print join("\t", "Top orf hit", $tophit->{idname}, $tophit->{gi}) . "\n";
			while(my $irow = $intergene_h->fetchrow_hashref)
			{
				my ($contig, $start, $stop) = $irow->{idname} =~ /(contig_\d+)_(\d+)_(\d+)/;
				my $low_range = $orfrow->{start} - $search_length;
				my $high_range = $orfrow->{stop} + $search_length;
				my $istart = $start + $irow->{query_start};
				my $istop = $start + $irow->{query_end};
				if($irow->{gi} eq $tophit->{gi} )
				{
					if(  ( ($orfrow->{stop} + $search_length) >= $istart && $istop >= $orfrow->{stop}) || ( ($orfrow->{start} - $search_length) <= $istop && $istop <= $orfrow->{stop})  )
					{
						my $fasta_file = "temp/" . $id . ".fas";
						open(HITFAS, ">", $fasta_file);
						print join("\t", $id, $irow->{idname}, $istart, $istop, "gi:" . $irow->{gi}, 'orf:'. $orfrow->{orfid}, $orfrow->{contig}, $orfrow->{start}, $orfrow->{stop}) . "\n";
						my $intergenic_seq_match = $irow->{query_string};
						$intergenic_seq_match =~ s/\ //g;
						$intergenic_seq_match =~ s/\-//g;
						print HITFAS get_fasta_sequence($irow->{gi});
						my $seq = Bio::Seq->new( -seq=> $orfrow->{sequence}, -id=>$orfrow->{orfid});
						print HITFAS ">" .  $orfrow->{orfid} . "\n" . $seq->translate->seq() . "\n";
						print HITFAS ">" . $irow->{idname} . "\n" . $intergenic_seq_match;
						close(HITFAS);
						system("/bioware/muscle/muscle -in $fasta_file -html -out $id.html");
						system("/bioware/muscle/muscle -in $fasta_file -clw -out $id.aln");
						$id++;
					}
				}
				
			}
		} else
		{
#			print "No intergenic spaces found on this contig\n";
		}
	} else
	{
#		print "No similarities found\n";
	}
}

sub get_fasta_sequence
{
	my $gi_num = shift;
	my $ret_sequence;
	$ret_sequence = `fastacmd -s $gi_num`;
	
	return $ret_sequence;
}

