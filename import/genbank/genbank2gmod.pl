#!/usr/bin/perl

# This script will import a file of genbank entries into our mbl gmod database and will create all of the necessary pre pipeline information
# Usage: ./genbank2gmod.pl giardia giardia_sequences.gb

use strict;

use Bio::SeqIO;
use Mbl;
use CGI qw(:all);
use CGI::Pretty;
use DBI;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;

my $embl_file = $ARGV[1];
my $debug = 0;
my $insert_database = 1;


my $insert_contig 		= $dbh->prepare('insert into links (super_id, bases_in_super, contigs_in_super, ordinal_number, contig_length, gap_before_contig, gap_after_contig, contig_number, contig_start_super_base, modified_contig_start_base, modified_bases_in_super) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
my $insert_contig_seq 		= $dbh->prepare('insert into contigs (contig_number, bases) values (?, ?)');
my $insert_read 		= $dbh->prepare('insert into reads (read_name) values (?)');
my $insert_into_read_assembly 	= $dbh->prepare('insert into reads_assembly (read_name, read_len_untrim, first_base_of_trim, read_len_trim, contig_number, contig_length, trim_read_in_contig_start, trim_read_in_contig_stop, orientation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
my $insert_reads_bases		= $dbh->prepare('insert into reads_bases (read_name, bases) VALUES (?, ?)');
my $insert_orf 			= $dbh->prepare('insert into orfs (orfid, orf_name, annotation, annotation_type, source, contig, start, stop, direction, delete_fg, delete_reason, sequence) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
my $insert_annotation		= $dbh->prepare('insert into annotation (userid, orfid, update_dt, annotation, notes, delete_fg, blessed_fg, qualifier, with_from, aspect, object_type, evidence_code, private_fg) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');


my $in = Bio::SeqIO->new(-file=>$embl_file,-format=>'GENBANK');

my $num_to_import = 1;

while (my $seq = $in->next_seq) {

	my $sequence_id = $seq->display_id;
	my $length = $seq->length;
	my $sequence = $seq->seq();

	if($debug)
	{
		print "##############################################################\n";
		print "START GENE:\t$sequence_id\n";
		print "  Size: $length\n";
		print "  Sequence\n$sequence\n\n";
	}

	# Find a new contig/supercontig for this entry.
	my $supercontig_id = get_largest_supercontig()+1;
	my $contig_id = get_largest_contig() + 1;
	# Insert into the assembly tables
	if($insert_database)
	{
		$insert_contig->execute($supercontig_id, $length, 1, 1, $length, 0, 0, $contig_id, 1, 1, $length);
		$insert_contig_seq->execute('contig_' . $contig_id, $sequence);
		$insert_read->execute($sequence_id);
		$insert_into_read_assembly->execute($sequence_id, $length, 1, $length, $contig_id, $length, 1, $length, '+');
		$insert_reads_bases->execute($sequence_id, $sequence);
	}

	
        foreach my $feat ($seq->top_SeqFeatures) 
	{

		my $dir = "+";
		if($feat->strand == -1)
		{
			$dir = '-';
		} elsif($feat->strand == 0)
		{
			$dir = '.';
		}
		my $feat_start = $feat->start;
		my $feat_stop = $feat->end;
		my $feat_sequence = $feat->seq()->seq();
		if($feat->start > $feat->end)
		{
			my $t = $feat_start;
			$feat_start = $feat_stop;
			$feat_stop = $t;
		}

		if($debug)
		{
			print "----------------------------------------------------------------\n";
			print "    Start:  " . $feat->start . "\n";
			print "    Stop:   " . $feat->end . "\n";
			print "    Dir:    " . $feat->strand . "\n";
			print "    Source  " . $feat->source_tag . "\n";
			print "    Primary " . $feat->primary_tag . "\n";
			print "    Seq:    " . $feat_sequence . "\n\n";
			
			print "  Features:\n";
			foreach my $tag ($feat->get_all_tags() )
			{
				print "    $tag\n" . join("\n", $feat->get_tag_values($tag)) . "\n";
			}
		
	                my $gffstring =  $feat->gff_string;
			print   "GFF " . $gffstring . "\n";
			print "----------------------------------------------------------------\n";
		}

		# Is this a gene
		my $feat_hash;
		my $note_text = '';
		my $gene = '';
		my $product = '';
		foreach my $tag ($feat->get_all_tags() )
		{
			
			if($tag eq 'gene')
			{
				$gene = join(". ", $feat->get_tag_values($tag));

			} elsif($tag eq 'product')
			{
				$product = join(". ", $feat->get_tag_values($tag));
			}else
			{
				$note_text .= $tag . ':' . join(". \n", $feat->get_tag_values($tag)) . "\n";
			}
	
		}

		# If this was a gene, then lets create an orf for it.
		if( $feat->primary_tag eq 'CDS' )
		{
			if($insert_database)
			{
				my $orfid = get_max_orfid()+1;
				if($debug)
				{
					print "##CREATING ORF $orfid##\n";
				}
				my $gene_name = $gene;
				if($gene_name eq '')
				{
					$gene_name = $product;
				} elsif($product ne '')
				{
					$gene_name = $gene . ' - ' . $product;
				} else
				{
					$gene_name = 'unnamed';
				}
				$insert_orf->execute($orfid, $sequence_id, undef, undef, 'GENBANK', 'contig_' . $contig_id, $feat_start, $feat_stop, $dir, 'N', undef, $feat_sequence);
				$insert_annotation->execute(1, $orfid, undef, $gene_name, $note_text, 'N', 'Y', undef, undef, undef, undef, undef, 'N');
			}
			
		}
        }

	if($debug)
	{
		print "END GENE:\t$sequence_id \n\n";
		print "##############################################################\n";
	}

}

exit;

sub get_largest_contig
{
	my $sth = $dbh->prepare("select max(contig_number) as max_id from links");
	$sth->execute();
	return $sth->fetchrow_hashref->{max_id};


}

sub get_largest_supercontig
{
	my $sth = $dbh->prepare("select max(super_id) as max_id from links");
	$sth->execute();
	return $sth->fetchrow_hashref->{max_id};
}
sub get_max_orfid
{
	my $sth = $dbh->prepare("select max(orfid) as max_id from orfs");
	$sth->execute();
	return $sth->fetchrow_hashref->{max_id};
}
