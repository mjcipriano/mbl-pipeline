#!/usr/bin/perl

# This script will import a file of fasta entries into our mbl gmod database and will create all of the necessary pre pipeline information
# Usage: ./fasta2gmod.pl giardia giardia_contigs.fasta

use strict;

use Bio::SeqIO;
use Mbl;
use CGI qw(:all);
use CGI::Pretty;
use DBI;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;

my $fasta_file = $ARGV[1];
my $debug = 0;
my $insert_database = 1;


my $insert_contig 		= $dbh->prepare('insert into links (super_id, bases_in_super, contigs_in_super, ordinal_number, contig_length, gap_before_contig, gap_after_contig, contig_number, contig_start_super_base, modified_contig_start_base, modified_bases_in_super) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
my $insert_contig_seq 		= $dbh->prepare('insert into contigs (contig_number, bases) values (?, ?)');
my $insert_read 		= $dbh->prepare('insert into reads (read_name) values (?)');
my $insert_into_read_assembly 	= $dbh->prepare('insert into reads_assembly (read_name, read_len_untrim, first_base_of_trim, read_len_trim, contig_number, contig_length, trim_read_in_contig_start, trim_read_in_contig_stop, orientation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
my $insert_reads_bases		= $dbh->prepare('insert into reads_bases (read_name, bases) VALUES (?, ?)');
my $insert_orf 			= $dbh->prepare('insert into orfs (orfid, orf_name, annotation, annotation_type, source, contig, start, stop, direction, delete_fg, delete_reason, sequence) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
my $insert_annotation		= $dbh->prepare('insert into annotation (userid, orfid, update_dt, annotation, notes, delete_fg, blessed_fg, qualifier, with_from, aspect, object_type, evidence_code, private_fg) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');


my $in = Bio::SeqIO->new(-file=>$fasta_file,-format=>'fasta');

my $num_to_import = 1;

while (my $seq = $in->next_seq) {

	my $sequence_id = $seq->display_id;
	my $length = $seq->length;
	my $sequence = $seq->seq();

	if($debug)
	{
		print "##############################################################\n";
		print "START CONTIG:\t$sequence_id\n";
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

	
	if($debug)
	{
		print "END CONTIG:\t$sequence_id \n\n";
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
