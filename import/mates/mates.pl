#!/usr/bin/perl -w
use strict;

# This script will import files in arachne format into our mbl gmod database and will create all of the necessary pre pipeline information
# Usage: ./arachne2gmod.pl database projectdir


use Bio::SeqIO;
use Mbl;
use CGI qw(:all);
use CGI::Pretty;
use DBI;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;


my $debug = 0;

#Create dbh prepare statements
my $select_reads_assembled = $dbh->prepare("

		SELECT 
	                 reads_assembly.read_name,
			 reads_assembly.trim_read_in_contig_start,
			 reads_assembly.trim_read_in_contig_stop,
			 reads_assembly.contig_number,
			 reads_assembly.orientation,
			 links.super_id
		FROM     reads_assembly,
			 links
		WHERE    reads_assembly.contig_number = links.contig_number
			 AND reads_assembly.read_name like 'SOLEXA-%'
		");

my $select_read = $dbh->prepare("select read_name, trim_read_in_contig_start, trim_read_in_contig_stop, orientation, contig_number from reads_assembly where read_name = ?");
my $update_unplaced_status = $dbh->prepare("update reads set status = ? where read_name = ?");
my $update_read = $dbh->prepare("update reads_assembly set read_pair_name = ?, read_pair_status = ?, read_pair_contig_number = ?, observed_insert_size = ? where read_name = ?");

# For solexa
# update `reads` set template_id = LEFT(read_name, length(read_name)-2) where read_name like 'SOLEXA-%'
#
$select_reads_assembled->execute();
my %read_hash;
my %read_partner;

while(my $read = $select_reads_assembled->fetchrow_hashref)
{

	my $read_name = $read->{read_name};
	my $partner_name = $read_name;
	if($read_name =~ /1$/)
	{
		$partner_name =~ s/\/1/\/2/;
	} else
	{
		$partner_name =~ s/\/2/\/1/;
	}
	$read_hash{$read_name} = $read;
	$read_partner{$read_name} = $partner_name;

}

foreach my $read_name (keys %read_hash)
{

	my $partner_type = '';
	my $partner_name = $read_partner{$read_name};
	my $partner_contig = undef;
	my $read = $read_hash{$read_name};
	my $distance = undef;

	# Get my supercontig coords 
	my (undef, $read_super_start, $read_super_stop) = $mbl->get_supercontig_coords_from_contig($read->{contig_number}, $read->{trim_read_in_contig_start}, $read->{trim_read_in_contig_stop});
	my ($partner_super_start, $partner_super_stop) = (0, 0);


	# First check if I have a partner
	if( !exists($read_hash{$partner_name}) )
	{
		$partner_type = 'missing-partner';
	} elsif($read->{super_id} ne $read_hash{$partner_name}->{super_id})
	{
		$partner_type = 'partner-different-supercontig';
	} else
	{

		my $read_partner_read = $read_hash{$partner_name};
		(undef, $partner_super_start, $partner_super_stop) = $mbl->get_supercontig_coords_from_contig($read_partner_read->{contig_number}, $read_partner_read->{trim_read_in_contig_start}, $read_partner_read->{trim_read_in_contig_stop});

		$partner_contig = $read_partner_read->{contig_number};
		if($read_partner_read->{contig_number} == $read->{contig_number})
		{
			$partner_type = 'partner-same-contig';
		} else
		{
			$partner_type = 'partner-different-contig-positive-gap';
		}

		# They are in the same supercontig. Now what is their position and direction within this supercontig
		
		if($read_super_start < $partner_super_start)
		{
			$distance = $partner_super_start - $read_super_stop;
		} else
		{
			$distance = $read_super_stop - $partner_super_start;
		}
		
	}

	$update_read->execute($partner_name, $partner_type, $partner_contig, $distance, $read_name);
	if(!defined($distance))
	{
		$distance = 0;
	}
	if(!defined($partner_contig))
	{
		$partner_contig = 0;
	}
	print join("\t", $read_name, $partner_type, $read->{super_id}, $read_super_start, $read_super_stop, $partner_name, $partner_super_start, $partner_super_stop, $distance) . "\n";
	
}

