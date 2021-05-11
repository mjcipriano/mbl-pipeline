#!/usr/bin/perl

use strict;

use Mbl;
use Bio::SeqIO;
use Bio::Seq;

my $organism = $ARGV[0];
my $mbl = Mbl::new(undef, $organism);
my $dbh = $mbl->dbh;


my $gap = 5000;
my $min_gap = 100;
my $gap_char = 'N';
my $contigs_h = $dbh->prepare("select contig_number, bases from contigs where contig_number = ?");
my $links_h = $dbh->prepare("select super_id, contig_number, ordinal_number, gap_before_contig from links order by super_id, ordinal_number");
my $contig_orfs_h = $dbh->prepare("select orfid, contig, start, stop, direction from orfs where delete_fg = 'N' AND contig = ?");


my $order_array;
my $gap_array;
my $contig_array;
my $sequence = '';
my $last_pos = 0;

# Open the orfs and the sequence output file
open(ORFS, ">", $organism . "_orfs.tab");

# Create an array of the order of the contigs;
$links_h->execute();

my $last_supercontig = 0;
while(my $link_row = $links_h->fetchrow_hashref)
{
	print ".";
	push(@$order_array, 'contig_' . $link_row->{contig_number});

	# Find out what the gap is before this contig
	if($last_supercontig != $link_row->{super_id})
	{
		push(@$gap_array, $gap);
	} elsif($link_row->{gap_before_contig} < 0)
	{
		push(@$gap_array, $min_gap);
	} else
	{
		push(@$gap_array, $link_row->{gap_before_contig});
	}
	$last_supercontig = $link_row->{super_id};
}


print "\n\n";
my $array_pos = 0;
foreach my $contig_num(@$order_array)
{
	# Get the contig bases
	$contigs_h->execute($contig_num);
	if($contigs_h->rows < 1)
	{
		print "\nERROR in $contig_num\n";
	} else
	{
		print "+";
		my $contig = $contigs_h->fetchrow_hashref;

		# Insert the gap before this contig
		my $gap_seq = '';
		for(1..$gap_array->[$array_pos])
		{
			$gap_seq .= $gap_char;
		}
		$sequence .= $gap_seq . uc($contig->{bases});
		$contig_orfs_h->execute($contig_num);
		$last_pos += $gap_array->[$array_pos];
		if($contig_orfs_h->rows > 0)
		{
			# Get all the orfs
			while(my $orf_row = $contig_orfs_h->fetchrow_hashref)
			{
				print "-";
				my $start = $orf_row->{start};
				my $dir = "1";
				if($orf_row->{direction} eq "-")
				{
					$start = $orf_row->{stop};
					$dir = "-1";
				}
				print ORFS join("\t", $orf_row->{orfid}, $last_pos + $start, $dir) . "\n";
			}
			
		}
		$last_pos += length($contig->{bases});
		
	}
	$array_pos++;
}

close(ORFS);
# Now we have a big sequence
my $seq = Bio::Seq->new(-display_id=>$organism, -seq=>$sequence);
my $seqio = Bio::SeqIO->new(-file=>">$organism" . "_genome_seq.fasta", -format=>'fasta');
$seqio->write_seq($seq);


