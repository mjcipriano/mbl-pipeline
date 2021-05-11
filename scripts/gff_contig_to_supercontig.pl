#!/usr/bin/perl

# This script will take via stdin a gff file that is referenced by contig and spit out a gff file that is referenced by supercontig.
# The links table must be correctly set up for this to work
# Usage ./gff_contig_to_supercontig.pl giardia < contig_feature.gff > supercontig_feature.gff

use Mbl;


my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;


while(<>)
{
	if($_ =~ /^\#/)
	{
		next;
	}
	my @line = split("\t", $_);
	my $contig = $line[0];
	my $start = $line[3];
	my $stop = $line[4];
	#($contig) = $contig =~ /contig_(\d+)/;
	my ($super_id, $new_start, $new_stop) = $mbl->get_supercontig_coords_from_contig($contig, $start, $stop, 1);
	$line[0] = 'supercontig_' . $super_id;
	$line[3] = $new_start;
	$line[4] = $new_stop;
	print join("\t", @line);
}
