#!/usr/bin/perl
 
 
use strict;
 
use Bio::DB::GFF;
 
use Mbl;
 
my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;
 
 
my $debug = 10;


my $orfid = 0;
my $category = '';
my $result = '';
my $prob = '';
my $odds = '';
my $full_report = '';


my $insert_protfun_fulldata = $dbh->prepare("insert into blast_report_full (idname, report, sequence_type_id, db_id, algorithm_id) VALUES (?, ?, ?, ?, ?)");
my $delete_protfun_fulldata = $dbh->prepare("delete from blast_report_full where idname = ? AND sequence_type_id = ? AND db_id = ? AND algorithm_id = ?");
my $delete_protfun_annotation = $dbh->prepare("delete from annotation where orfid = ? AND userid = ?");
my $insert_protfun_search_results = $dbh->prepare("insert into blast_results (idname, accession_number, description, algorithm, db, evalue, sequence_type_id, primary_id, query_start, query_end, gi, hit_name, score) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

my $evidence_id = 7;

# Get protfun db_id
my $db_id = $mbl->get_db_id('protfun');
my $algorithm_id = $mbl->get_algorithm_id('protfun');
my $sequence_type_id = $mbl->get_sequence_type_id("orf");
my $protfun_id = $mbl->get_id_from_username("protfun");


if(!$db_id || !$algorithm_id || !$sequence_type_id || !$protfun_id)
{
	die ("The database does not have protfun as a database type");
}

my $category_array;

while(<>)
{
	my $line = $_;
	if($line =~ /^##/)
	{
		next;
	}
	if($line =~ /^\>/)
	{
		($orfid) = $line =~ /^\>(\d+)/;
		chomp($orfid);
		if($debug > 4)
		{
			print "Orf:$orfid\n";
		}
		# New orf, delete all data for this orf
		$delete_protfun_fulldata->execute($orfid, $sequence_type_id, $db_id, $algorithm_id);
		$delete_protfun_annotation->execute($orfid, $protfun_id);
	} elsif($line =~ /^#\ /)
	{
		($category) = $line =~ /^#\ (.+)Prob.+$/;
		$category =~ s/\s+$//;
	} elsif($line =~ /^\/\//)
	{
		# Time to insert into the database and clear out the hashes
		$full_report .= $line;
		if($debug > 4)
		{
			print "FULL REPORT FOR ORF $orfid\n";
			print $full_report;
			print "Relevant Categories\n";
		}
		foreach my $result_hash(@$category_array)
		{
			print "  Category:" . $result_hash->{'category'} . "\tResult:" . $result_hash->{result} . "\t" . $result_hash->{'probability'} . "\t" . $result_hash->{'odds'} . "\n";
		#	$mbl->add_annotation($protfun_id, $orfid, $result_hash->{'category'} . ":" . $result_hash->{result}, "Category:" . $result_hash->{'category'} . " Result:" . $result_hash->{result} . " Probability:" . $result_hash->{'probability'} . " Odds:" . $result_hash->{'odds'}, 'N', 'N', undef, undef, undef, 'protein', $evidence_id, 'N');
			$insert_protfun_search_results->execute($orfid, $result_hash->{result}, $result_hash->{'category'} . ":" . $result_hash->{result}, $algorithm_id, $db_id, undef, $sequence_type_id, undef, undef, undef, undef, $result_hash->{result}, $result_hash->{'odds'});

		}

		# Insert into the database for this orfid
		$insert_protfun_fulldata->execute($orfid, $full_report, $sequence_type_id, $db_id, $algorithm_id);
		$category_array = undef;
		$full_report = '';

	} else
	{
		if($line =~ /\=\>/)
		{
			#($result, $prob, $odds) = $line =~ /^\s+(\w+)\s+([0-9\.]+)\s+([0-9\.]+)\s*$/;
			($result, $prob, $odds) = $line =~ /^\s+(.+)\s+\=\>\s*([\d\.]+)\s+([\d\.]+)\s*$/;
			chomp($result);
			chomp($prob);
			chomp($odds);

			my $res_hash = {'category'=>$category, 'result'=>$result, 'probability'=>$prob, 'odds'=>$odds};
			push(@$category_array, $res_hash);
		}
	}
	if($line =~  /^\/\//)
	{ 
		# Do nothing
	} else
	{
		$full_report .= $line;
	}
}
