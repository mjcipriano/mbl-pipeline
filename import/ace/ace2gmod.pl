#!/usr/bin/perl -w
use strict;

# This script will import files in arachne format into our mbl gmod database and will create all of the necessary pre pipeline information
# Usage: ./arachne2gmod.pl database projectdir


use Bio::SeqIO;
use Mbl;
use CGI qw(:all);
use CGI::Pretty;
use DBI;
use XML::DOM;

#Test commandline arguements
if (scalar @ARGV < 3) {
	print_usage();
	exit 1;
} elsif ($ARGV[0] eq "--help") {
	print_usage();
	exit 1;
}

if (! -d $ARGV[1]) {
	warn "Ace file: $ARGV[1] does not exist.  Exiting...\n";
	exit 1;
}
my $ace_file = $ARGV[1];

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;

my $cleanup = 0;
if (scalar @ARGV == 4) 
{
	if ($ARGV[3] eq "cleanup") {$cleanup = 1;}
}
	
my $debug = 0;


#Create dbh prepare statements
#my $insert_links = $dbh->prepare('insert into links (super_id, bases_in_super, contigs_in_super, ordinal_number, contig_length, gap_before_contig, gap_after_contig, contig_number, contig_start_super_base, modified_contig_start_base, modified_bases_in_super) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');

my $insert_links = $dbh->prepare('insert into links (super_id, bases_in_super, contigs_in_super, ordinal_number, contig_length, gap_before_contig, gap_after_contig, contig_number) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');

my $insert_contigs = $dbh->prepare('insert into contigs (contig_number, bases) values (?, ?)');

my $update_links_contig_start = $dbh->prepare('UPDATE links set contig_start_super_base =  ? WHERE contig_number = ?' );

my $update_reads_query = $dbh->prepare('insert into reads_assembly (read_name, read_status, read_len_untrim, first_base_of_trim, read_len_trim, contig_number, contig_length, trim_read_in_contig_start, trim_read_in_contig_stop, orientation, read_pair_name, read_pair_status, read_pair_contig_number, observed_insert_size, given_insert_size, given_insert_std_dev, observed_inserted_deviation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');

my $check_read_existence_h = $dbh->prepare("select read_id, read_name from reads where read_name = ?");

my $insert_read = $dbh->prepare('insert into reads (read_name) values (?)');

my $insert_reads_assembly = $dbh->prepare('insert into reads_assembly (read_name, read_status, read_len_untrim, first_base_of_trim, read_len_trim, contig_number, contig_length, trim_read_in_contig_start, trim_read_in_contig_stop, orientation, read_pair_name, read_pair_status, read_pair_contig_number, observed_insert_size, given_insert_size, given_insert_std_dev, observed_inserted_deviation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');

my $insert_reads_bases = $dbh->prepare('insert into reads_bases (read_name, bases) VALUES (?, ?)');

my $insert_reads_qual = $dbh->prepare("insert into reads_quality (read_name, quality) VALUES (?, ?)");

my $insert_contig_qual = $dbh->prepare("insert into contig_quality (contig_number, quality) VALUES (?, ?)");

my $update_unplaced_status = $dbh->prepare("update reads set status = ? where read_name = ?");

my $insert_reads_xml = $dbh->prepare('insert into reads (read_name, center_name, plate_id, well_id, template_id, library_id, trace_end, trace_direction) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');


# Find a new contig/supercontig for this entry.
my $supercontig_id = get_largest_supercontig() + 1;
my $contig_id = get_largest_contig() + 1;

	if ($debug)
	{
		print "######################################################\n";
		print "START: assembly.links\n";
	}

	open(ACE, "$ace_file") or die("Cannot open $ace_file");
	while (<ACE>)
	{
    	my $line = $_;
		chomp $line;
	}
	close(ACE);

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
