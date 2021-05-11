#!/usr/bin/perl


# This file takes a tab delimited output of a interpro run and will insert it into the appropriate tables of the database. It takes one argument (database name) and the input file
#   ex. ./import_interpro giardia interprofile.tab

use strict;
                                                                                                                                                                                                                                                    
use DBI;
use Mbl;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $input_file = $ARGV[1];

my $dbh = $mbl->dbh();

my $debug = 0;

my $insert_blast_q = $dbh->prepare("insert into blast_results (idname, accession_number, description, algorithm, db, evalue, sequence_type_id, primary_id, query_start, query_end, gi, hit_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

my $st = $dbh->prepare("select id,name from algorithms");
$st->execute();
while(my $a = $st->fetchrow_hashref)
{
	if($debug)
	{
		print join("\t", $a->{id}, $a->{name}) . "\n";
	}
}
if($debug)
{
	print join("\t", 'idname', 'accession_number','description', 'algorithm', 'db', 'evalue', 'sequence_type_id', 'primary_id', 'query_start', 'query_end', 'gi', 'hit_name') ."\n";
}
open(FILE, $input_file);
while(<FILE>)
{
	my $line = $_;
	chomp($line);

	my ($idname, $crc, $length, $method, $accession_number, $description, $start, $end, $evalue, $status, $date, $primary_id, $ipr_description, $goid) = split("\t", $line);

	my $algorithm_id = $mbl->get_algorithm_id(lc($method));

	my $db_id = $mbl->get_db_id('interpro');
	my $seq_type_id = $mbl->get_sequence_type_id('orf');

	if(!defined($algorithm_id) || !defined($db_id) || !defined($seq_type_id))
	{
		warn("Skiping line: $line");
		next;
	}
	if($evalue < 1e-0  || $evalue eq 'NA')
	{
		if($evalue eq 'NA')
		{
			$evalue = undef;
		}

		if($primary_id eq 'NULL')
		{
			$primary_id = undef;
		}

		if($ipr_description eq 'NULL')
		{
			$ipr_description = undef;
		}
		my $insert_description = undef;
		if($ipr_description ne undef || $goid ne undef)
		{
			$insert_description = $ipr_description . ' | ' . $goid;
		} 
		

		if($debug)
		{
			print join("\t", $idname, $accession_number, $description, $algorithm_id, $db_id, $evalue, $seq_type_id, $primary_id, $start, $end, undef, $insert_description) . "\n";
		}
		$insert_blast_q->execute($idname, $accession_number, $description, $algorithm_id, $db_id, $evalue, $seq_type_id, $primary_id, $start, $end, undef, $ipr_description . ' | ' . $goid);
	}

}
