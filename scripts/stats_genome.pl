#!/usr/bin/perl

# This script will update the stats table and html pages of the database.  It takes 3 arguments on the command line.
# Database name, genome size (numerical), genome size (text)
# Usage: ./update_stats.pl giardia 12000000 "12 Mbp"

use Mbl;
use Bio::SeqIO;
use Bio::Seq;
use Statistics::Descriptive;
use Getopt::Long;  
# Connect to the database
use DBI;
use File::Temp qw/ tempfile tempdir /;
  
use strict;

#my $database = "emiliania02";
#my $genome_size = "1000000";
#my $genome_text_size = "unknown";

#my $database = "emiliania03";
#my $genome_size = "10000000";
#my $genome_text_size = "unknown";

#my $database = "aureococcus";
#my $genome_size = "10000000";
#my $genome_text_size = "unknown";

#my $database = "t_bruceirhodesiense";
#my $genome_size = "26000000";
#my $genome_text_size = "26 Mbp";

#my $database = "t_bruceibrucei02";
#my $genome_size = 26000000;
#my $genome_text_size = "26 Mbp";

#my $database = $ARGV[0];
#my $genome_size = $ARGV[1];
#my $genome_text_size = $ARGV[2];

my $database = undef;
my $genome_size = undef;
my $genome_text_size = undef;
my $is_est = "F";

#my $database = "t_bruceigambiense";
#my $genome_size = 26000000;
#my $genome_text_size = "26 Mbp";

#my $database = "t_cruzi";
#my $genome_size = 26000000;
#my $genome_text_size = "26 Mbp";

#my $database = "giardia14";
#my $genome_size = 11700000; 
#my $genome_text_size = "11.7 Mbp";

#my $database = "bacclosure";
#my $genome_size = 151000;
#my $genome_text_size = "151 Kbp";

#my $database = "blochmannia06";
#my $genome_size = 791652;
#my $genome_text_size = "791,652bp";


#my $database = "antonospora01";
#my $genome_size = "5300000";
#my $genome_text_size = "5.3 Mbp";


my $hist_cgi = "/perl/graph_bar?";
my $hist_est = "/perl/graph_est";
#my $hist_cgi = "/cgi-bin/graph_bar?";
#my $hist_est = "/cgi-bin/graph_est";
my $debug = 1;
my $cov_est_bin = "/xraid/bioware/linux/seqinfo/bin/cov_est";

my $result_vars = GetOptions (	"organism=s" => \$database,
				"genome_size=i" => \$genome_size,
				"genome_text_size=s"=> \$genome_text_size,
				"is_est=s"=> \$is_est
				);

if ($is_est =~ /^t/i) 
{
	$is_est = 1; 
} elsif ($is_est =~ /^f/i) {
	$is_est = 0;
} elsif ($is_est !~ /[01]/) {
	$is_est = undef;
}

if(!$database || !$genome_size || !$genome_text_size || !defined $is_est)
{
	print "
This program will compute various statistics for an mbl gmod database.
--organism          The name of the organism database.
--genome_size       The size of the genome using only numbers
--genome_text_size  A textual representation of the size of the genome (eg, 1 Mbp, 40 Kbp)
--is_est            Are the data expressed sequence tags (ESTs)? (eg, T or F; default=F)
";
	exit;
}
my $mbl = Mbl::new(undef, $database);
my $dbh = $mbl->dbh();
 

$dbh->do("DELETE FROM stats");
my $insh = $dbh->prepare("insert into stats (type, statistic, value) VALUES (?, ?, ?)");

my $inshtml = $dbh->prepare("insert into html (template, variable, value) VALUES (?, ?, ?)");

my $typeq = $dbh->prepare("select type, statistic, value from stats where type = ? AND statistic != 'title'");
my $gettitle = $dbh->prepare("select type, statistic, value from stats where type = ? AND statistic = 'title'");
my $setpage = $dbh->prepare("update templates set template_file=? where page_name='assembly'");



#### CREATE SAGE TAG STATS
if ($debug) {print "Running SAGE tag stats\n";}

# Total number of Sagetags

my $num_sage_libraries = 0;
my $reduced_text = "";
my $num_sage_tags_reduced = 0;
my $total_map_orf = 0;
my $total_map_orf_reduced = 0;

my $seqh = $dbh->prepare("select count(*) as seqs from sage_tags");
$seqh->execute();
my $num_sage_tags = $seqh->fetchrow_hashref->{seqs};
if($num_sage_tags > 0)
{

	$insh->execute("sagetagmap", "<center>Statistic</center>", "</b><center>Unique <br>Tag Sequences</center></td><td><center>All <br>Sampled Tags</center><b>");

	$insh->execute("sage", "Total number of unique sage tags", commify($num_sage_tags));

	$reduced_text = "filtered";
	# Total sage tags filtered

	my $seqh = $dbh->prepare("select distinct sr.tagid from sage_results sr LEFT OUTER JOIN tagmap tm on sr.tagid = tm.tagid where ( tm.contig is not null OR sr.result >= 2)");
	$seqh->execute();

	$num_sage_tags_reduced = $seqh->rows;
	my $sage_in_query_reduced = ' (0';
	while(my $sage_row = $seqh->fetchrow_hashref)
	{
		$sage_in_query_reduced .= ', ' . $sage_row->{tagid};
	}
	$sage_in_query_reduced .= ')';

	my $tottagsamp = $dbh->prepare("select sum(total_filtered) as tot from sage_library_names");
	$tottagsamp->execute();
	my $tags_sampled = $tottagsamp->fetchrow_hashref->{tot};

	$insh->execute("sage", "Total number of unique sage tags ($reduced_text)", commify($num_sage_tags_reduced));
	$insh->execute("sagetagmap", "Total Number of Unique Tag Sequences", '<center>' . commify($num_sage_tags_reduced) . "</center></td><td><center><b>" . commify($tags_sampled) . "</center></b>");




	if ($debug) {print "Running SAGE tag library stats\n";}
	# Total number of libraries
	my $seqh = $dbh->prepare("select distinct library from sage_results");
	$seqh->execute();
	$num_sage_libraries = $seqh->rows;;
	#$insh->execute("sage", "Total number Sage libraries", commify($$num_sage_libraries));


	# Find filtered totals for each library (and create hash)
	$seqh = $dbh->prepare("select sn.name, sn.short_name, sum(sr.result) total from sage_results sr, sage_library_names sn where sn.library = sr.library AND sr.tagid IN $sage_in_query_reduced  group by sn.name order by sn.library");
	$seqh->execute();
	my $filtered_hash;
	while(my $row = $seqh->fetchrow_hashref)
	{
		$filtered_hash->{$row->{short_name}} = $row->{total};
	}


	# Total sage tags in each library

	$seqh = $dbh->prepare("select sn.name, sn.short_name, sum(sr.result) total from sage_results sr, sage_library_names sn where sn.library = sr.library group by sn.name order by sn.library");
	$seqh->execute();
	$insh->execute("sagelibraries", '<center>SAGE Library</center>', '</b>Acronym</td><td><center>Total Tags<br>Sampled</center></td><td><center>Putative<br>Sequencing<br>Error Tags</center></td><td><center>Total Tags Used<br>in Analyses</center><b>');
	while(my $row = $seqh->fetchrow_hashref)
	{
		$insh->execute("sagelibraries",   "<center>" . $row->{name}  , '</center></b>' . '<center>' . $row->{short_name} . '</center></td><td><center><b>' . commify($row->{total}) . '</b></center></td><td><center><b>' . commify($row->{total} - $filtered_hash->{$row->{short_name}}) . '</b></center></td><td><center><b>' . commify($filtered_hash->{$row->{short_name}}) . "</center>" );
	}



	if ($debug) {print "Running SAGE tag contig stats\n";}
	# How many map to a contig
	$seqh = $dbh->prepare("select distinct tagid from tagmap");
	$seqh->execute();
	my $total_tag_maped = $seqh->rows;
	my $percent_tag_mapped = ($total_tag_maped / $num_sage_tags) * 100;

	my $tagmap_samp_h = $dbh->prepare("select sum(sr.result) as tot from sage_results sr, (select distinct tagid from tagmap) st where st.tagid = sr.tagid");
	$tagmap_samp_h->execute();
	my $tagmap_samp = $tagmap_samp_h->fetchrow_hashref->{tot};
	$insh->execute("sage", "Tags that map to a contig", percent_it($percent_tag_mapped) );

	# How many map to a contig filtered
	$seqh = $dbh->prepare("select distinct tagid from tagmap where tagid IN " . $sage_in_query_reduced);
	$seqh->execute();
	my $total_tag_maped_reduced = $seqh->rows;
	my $percent_tag_mapped_reduced = ($total_tag_maped_reduced / $num_sage_tags_reduced) * 100;

	my $tagmap_samp_h = $dbh->prepare("select sum(sr.result) as tot from sage_results sr, (select distinct tagid from tagmap) st where st.tagid = sr.tagid");
	$tagmap_samp_h->execute();
	my $tagmap_samp = $tagmap_samp_h->fetchrow_hashref->{tot};
	my $tagnotmap_samp = $tags_sampled - $tagmap_samp;
	
	$insh->execute("sage", "Tags that map to a contig ($reduced_text)", percent_it($percent_tag_mapped_reduced));

	# what percent do not map to a contig filtered
	
	$insh->execute("sagetagmap", "Tags that Do Not Map to the Genome", '<center>' . percent_it((($num_sage_tags_reduced - $total_tag_maped_reduced)/ $num_sage_tags_reduced) * 100)  . "</center></td><td><center><b>" . percent_it( ($tagnotmap_samp/$tags_sampled) * 100) . "</b></center>" );

	# How many have a unique mapping

	$seqh = $dbh->prepare("select tagid, count(*) from tagmap group by tagid having count(*) = 1");
	$seqh->execute();
	my $total_map_once = $seqh->rows;
	my $percent_map_once = ($total_map_once / $num_sage_tags) * 100;
	$insh->execute("sage", "Tags that map only once", percent_it($percent_map_once));

	# How many have a unique mapping filtered
                                                                                                                                                                                                                                                       
	$seqh = $dbh->prepare("select tagid, count(*) from tagmap where tagid IN " . $sage_in_query_reduced . " group by tagid having count(*) = 1");
	$seqh->execute();
	my $total_map_once_reduced = $seqh->rows;
	my $percent_map_once_reduced = ($total_map_once_reduced / $num_sage_tags_reduced) * 100;
	$seqh = $dbh->prepare(" select sum(sr.result) as tot from sage_results sr,  (select tagid, count(*) from tagmap where tagid IN " . $sage_in_query_reduced . " group by tagid having count(*) = 1) st where st.tagid = sr.tagid ");
	$seqh->execute();
	my $total_map_once_sample = $seqh->fetchrow_hashref->{tot};

	$seqh = $dbh->prepare("select tagid, count(*) from tagmap where tagid IN " . $sage_in_query_reduced . " group by tagid having count(*) > 1");
	$seqh->execute();
	my $total_map_more_reduced = $seqh->rows;
	my $percent_map_more_reduced = ($total_map_more_reduced / $num_sage_tags_reduced) * 100;
	$seqh = $dbh->prepare(" select sum(sr.result) as tot from sage_results sr,  (select tagid, count(*) from tagmap where tagid IN " . $sage_in_query_reduced . " group by tagid having count(*) > 1) st where st.tagid = sr.tagid ");
	$seqh->execute();
	my $total_map_more_sample = $seqh->fetchrow_hashref->{tot};

	$insh->execute("sage", "Tags that map only once ($reduced_text)", percent_it($percent_map_once_reduced));
	$insh->execute("sagetagmap", "Tags that Map to One Location in the Genome", '<center>' . percent_it($percent_map_once_reduced) . "</center></td><td><center><b>" . percent_it( ($total_map_once_sample/$tags_sampled) * 100) . "</b></center>" );
	$insh->execute("sagetagmap", "Tags that Map to Multiple Locations in the Genome", '<center>' . percent_it($percent_map_more_reduced) . "</center></td><td><center><b>" . percent_it( ($total_map_more_sample/$tags_sampled) * 100) . "</b></center>" );
	
	# How many map to an orf?
	if ($debug) {print "Running SAGE tag orf stats\n";}

	$seqh = $dbh->prepare("select count(DISTINCT tagid) as ocount from orftosage");
	$seqh->execute();
	$total_map_orf = $seqh->fetchrow_hashref->{ocount};
	my $percent_map_orf = ($total_map_orf / $num_sage_tags) * 100;
	$insh->execute("sage", "Tags that map to an ORF", percent_it($percent_map_orf));


	# How many map to an orf filtered
                                                                                                                                                                                                                                                       
	$seqh = $dbh->prepare("select count(DISTINCT tagid) as ocount from orftosage where tagid IN " . $sage_in_query_reduced);
	$seqh->execute();
	$total_map_orf_reduced = $seqh->fetchrow_hashref->{ocount};
	my $percent_map_orf_reduced = ($total_map_orf_reduced / $num_sage_tags_reduced) * 100;

	$seqh = $dbh->prepare("select sum(sr.result) as tot from sage_results sr, (select distinct tagid from sage_tags where tagid IN $sage_in_query_reduced AND tagid NOT IN (select distinct tagid from orftosage)) st where st.tagid = sr.tagid");
	$seqh->execute();
	my $total_map_noorf_sample = $seqh->fetchrow_hashref->{tot};

	$seqh = $dbh->prepare("select sum(sr.result) as tot from sage_results sr, (select distinct tagid from orftosage) st where st.tagid = sr.tagid");
	$seqh->execute();
	my $total_map_orf_sample = $seqh->fetchrow_hashref->{tot};

	

	$insh->execute("sage", "Tags that map to an ORF ($reduced_text)", percent_it($percent_map_orf_reduced));
	$insh->execute("sagetagmap", "Tags Mapped to an Open Reading Frame", '<center>' . percent_it($percent_map_orf_reduced) . "</center></td><td><center><b>" . percent_it( ($total_map_orf_sample/$tags_sampled) * 100) . "</b></center>" );
	$insh->execute("sagetagmap", "Tags Not Mapped to an Open Reading Frame (UK)", '<center>' . percent_it(100 - $percent_map_orf_reduced)  . "</center></td><td><center><b>" . percent_it( ($total_map_noorf_sample/$tags_sampled) * 100) . "</b></center>" );



	# How many map to different types on ORFS

	# Query for number of tags sampled of a certain type;
	my $totaltagh = $dbh->prepare("select sum(result) as total_tags from sage_results where tagid IN (select distinct sr.tagid from sage_results sr LEFT OUTER JOIN tagmap tm on sr.tagid = tm.tagid where ( tm.contig is not null OR sr.result >= 2))");
	$totaltagh->execute();
	my $divnum = $totaltagh->fetchrow_hashref->{total_tags};
	my $numtagtypeh = $dbh->prepare("select sum(sr1.result) / $divnum as total_tags from sage_results sr1, orftosage os where sr1.tagid = os.tagid AND sr1.tagid IN (select distinct sr.tagid from sage_results sr LEFT OUTER JOIN tagmap tm on sr.tagid = tm.tagid where ( tm.contig is not null OR sr.result >= 2)) and os.tagtype = ?");

	$seqh = $dbh->prepare("select count(DISTINCT tagid) as ocount from orftosage where tagtype = 'Primary Sense Tag' AND tagid IN " . $sage_in_query_reduced);
	$seqh->execute();
	my $total_ps = $seqh->fetchrow_hashref->{ocount};
	$numtagtypeh->execute('Primary Sense Tag');
	my $tot_ps = $numtagtypeh->fetchrow_hashref->{total_tags};
	$insh->execute("sagetagmap", "Tags Mapped as Primary Sense Tags (PS)", '<center>' . percent_it( ($total_ps / $num_sage_tags_reduced) * 100) . "</center></td><td><center><b>" . percent_it($tot_ps * 100) . "</b></center>" );
	$numtagtypeh->execute('Primary Sense Tag');

        $seqh = $dbh->prepare("select count(DISTINCT tagid) as ocount from orftosage where tagtype = 'Primary Antisense Tag' AND tagid IN " . $sage_in_query_reduced);
        $seqh->execute();
        my $total_pa = $seqh->fetchrow_hashref->{ocount};
	$numtagtypeh->execute('Primary Antisense Tag');
        my $tot_pa = $numtagtypeh->fetchrow_hashref->{total_tags};
        $insh->execute("sagetagmap", "Tags Mapped as Primary Anti-Sense Tags (PA)", '<center>' . percent_it( ($total_pa/$num_sage_tags_reduced) * 100) . "</center></td><td><center><b>" . percent_it($tot_pa * 100) . "</b></center>" );


        $seqh = $dbh->prepare("select count(DISTINCT tagid) as ocount from orftosage where tagtype = 'Alternate Sense Tag' AND tagid IN " . $sage_in_query_reduced);
        $seqh->execute();
        my $total_as = $seqh->fetchrow_hashref->{ocount};
	$numtagtypeh->execute('Alternate Sense Tag');
        my $tot_as = $numtagtypeh->fetchrow_hashref->{total_tags};
        $insh->execute("sagetagmap", "Tags Mapped as Alternate Sense Tags (AS)", '<center>' . percent_it( ($total_as/$num_sage_tags_reduced) * 100) . "</center></td><td><center><b>" . percent_it($tot_as * 100) . "</b></center>");

        $seqh = $dbh->prepare("select count(DISTINCT tagid) as ocount from orftosage where tagtype = 'Alternate Antisense Tag' AND tagid IN " . $sage_in_query_reduced);
        $seqh->execute();
        my $total_aa = $seqh->fetchrow_hashref->{ocount};
	$numtagtypeh->execute('Alternate Antisense Tag');
	my $tot_aa = $numtagtypeh->fetchrow_hashref->{total_tags};
        $insh->execute("sagetagmap", "Tags Mapped as Alternate Anti-Sense Tags (AA)", '<center>' . percent_it( ($total_aa/$num_sage_tags_reduced) * 100) . "</center></td><td><center><b>" . percent_it($tot_aa * 100) . "</b></center>");









	$typeq->execute("sage");

	my $sage_snapshot = "<table width=\"60%\" border=3>";

	while(my $row = $typeq->fetchrow_hashref)
	{
		$sage_snapshot .= "<tr><td>" . $row->{statistic} . "</td><td><b>" . $row->{value} . "</b></td></tr>";
	}

	$sage_snapshot .= "</table>";

	$dbh->do("delete from html where variable = 'sage_datasnapshot' AND template = 'default'");

	$inshtml->execute("default", "sage_datasnapshot", $sage_snapshot);


} ## END IF NUM SAGETAGS > 0


#### ORF STATS
if ($debug) {print "Running ORF stats\n";}


# Total number of called orfs
$seqh = $dbh->prepare("select count(orfid) as ocount from orfs where delete_fg = 'N'");
$seqh->execute();
my $total_orfs = $seqh->fetchrow_hashref->{ocount};
$insh->execute("orf", "Number of Predicted ORFs", '<center>' . commify($total_orfs) . '</center>');



my $total_orfs_sage;

if($total_orfs > 0)
{
	if($num_sage_tags > 0)
	{

		# Number of orfs with expression detected by sage

		$seqh = $dbh->prepare("select distinct orfid from orftosage");
		$seqh->execute();
		 $total_orfs_sage  = $seqh->rows;
		my $percent_orfs_sage = ($total_orfs_sage / $total_orfs) * 100;
		$insh->execute("orf", "Transcribed ORFs (SAGE detection)", '<center>' . percent_it($percent_orfs_sage) .'</center>' );
	}

	# Number of ORFs passing Test Code
	$seqh = $dbh->prepare("select count(orfid) as ocount from orfs where TestCode = 'P' AND delete_fg = 'N'");
	$seqh->execute();
	my $total_orfs_one_test = $seqh->fetchrow_hashref->{ocount};
	my $percent_orfs_one_test = ($total_orfs_one_test / $total_orfs) * 100;
	$insh->execute("orf", "ORFs passing Test Code (test 1)", '<center>' . percent_it($percent_orfs_one_test) . '</center>');

	# Number of ORFs passing Gene Scan
	$seqh = $dbh->prepare("select count(orfid) as ocount from orfs where GeneScan = 'P' AND delete_fg = 'N'");
	$seqh->execute();
	my $total_orfs_two_test = $seqh->fetchrow_hashref->{ocount};
	my $percent_orfs_two_test = ($total_orfs_two_test / $total_orfs) * 100;
	$insh->execute("orf", "ORFs passing Gene Scan (test 2)", '<center>' . percent_it($percent_orfs_two_test) . '</center>');

	# Number of ORFs passing Codon Preference
	$seqh = $dbh->prepare("select count(orfid) as ocount from orfs where CodonPreference = 'P' AND delete_fg = 'N'");
	$seqh->execute();
	my $total_orfs_three_test = $seqh->fetchrow_hashref->{ocount};
	my $percent_orfs_three_test = ($total_orfs_three_test / $total_orfs) * 100;
	$insh->execute("orf", "ORFs passing Codon Preference (test 3)", '<center>' . percent_it($percent_orfs_three_test) . '</center>');


	# Number of orfs passing at least 1 of the tests

#	$seqh = $dbh->prepare("select count(orfid) as ocount from orfs where  ( (TestCode = 'P') OR (GeneScan = 'P') OR (CodonPreference = 'P')) AND delete_fg = 'N'");
#	$seqh->execute();
#	my $total_orfs_one_test = $seqh->fetchrow_hashref->{ocount};
#	my $percent_orfs_one_test = ($total_orfs_one_test / $total_orfs) * 100;
#	$insh->execute("orf", "ORFs passing one test", percent_it($percent_orfs_one_test) );

	# Number of orfs passing at least 2 of the tests
	
	$seqh = $dbh->prepare("select count(orfid) as ocount from orfs where ( (TestCode = 'P' AND GeneScan = 'P') OR (GeneScan = 'P' AND CodonPreference = 'P') OR ( TestCode = 'P' AND CodonPreference = 'P')) AND delete_fg = 'N'");
	$seqh->execute();
	my $total_orfs_two_test  = $seqh->fetchrow_hashref->{ocount};
	my $percent_orfs_two_test = $total_orfs_two_test / $total_orfs * 100;
	$insh->execute("orf", "ORFs passing Two of Three Tests", '<center>' . percent_it($percent_orfs_two_test) . '</center>');


	# Number of orfs passing at least 2 of the tests

#	$seqh = $dbh->prepare("select count(orfid) as ocount from orfs where TestCode = 'P' AND GeneScan = 'P' AND CodonPreference = 'P' AND delete_fg = 'N'");
#	$seqh->execute();
#	my $total_orfs_three_test  = $seqh->fetchrow_hashref->{ocount};
#	my $percent_orfs_three_test = $total_orfs_three_test / $total_orfs * 100;
#	$insh->execute("orf", "ORFs passing three tests", percent_it($percent_orfs_three_test));


	# Number of orfs with blast hit > e-10

	$seqh = $dbh->prepare("select distinct idname from blast_results where evalue < 1e-10 AND (description not like '%ATCC 50803%' OR description like '%gb|%') AND sequence_type_id = 2 AND db IN ('2', '3')");
	$seqh->execute();
	my $total_orfs_blast_hit  = $seqh->rows;
	my $percent_orfs_blast_hit = ($total_orfs_blast_hit / $total_orfs) * 100;
	$insh->execute("orf", "ORFs with BLAST E-value < 1e-10", '<center>' . percent_it($percent_orfs_blast_hit) . '</center>');

	# Number of orfs with blast hit > e-4

	$seqh = $dbh->prepare("select distinct idname from blast_results where evalue < 1e-4 AND (description not like '%ATCC 50803%' OR description like '%gb|%') AND sequence_type_id = 2 AND db IN ('2', '3')");
	$seqh->execute();
	my $total_orfs_blast_hit  = $seqh->rows;
	my $percent_orfs_blast_hit = ($total_orfs_blast_hit / $total_orfs) * 100;
	$insh->execute("orf", "ORFs with BLAST E-value < 1e-04", '<center>' . percent_it($percent_orfs_blast_hit) . '</center>');
 
}

#### Contig/ Assembly Stats
if ($debug) {print "Running Contig / Assembly stats\n";}

# Total number of contigs

$seqh = $dbh->prepare("select count(*) as total_contigs from links");
$seqh->execute();
my $total_contigs  = $seqh->fetchrow_hashref->{total_contigs};
$insh->execute("assembly", "Total number of contigs", commify($total_contigs));

# Total number of supercontigs

$seqh = $dbh->prepare("select distinct super_id from links");
$seqh->execute();
my $total_supercontigs  = $seqh->rows;
$insh->execute("assembly", "Total number of supercontigs", commify($total_supercontigs));


# Number of bases in contigs greater then 5kb

$seqh = $dbh->prepare("select sum(contig_length) as contig_sum from links where contig_length > 5000");
$seqh->execute();
my $sum_contig_length  = $seqh->fetchrow_hashref->{contig_sum};
$insh->execute("assembly", "Number of bases in contigs > 5kb", commify($sum_contig_length));

# Total Number of bases in contigs

$seqh = $dbh->prepare("select sum(contig_length) as contig_sum from links");
$seqh->execute();
my $sum_contig_length_all  = $seqh->fetchrow_hashref->{contig_sum};
$insh->execute("assembly", "Number of bases in all contigs", commify($sum_contig_length_all));

# Number of bases sampled and used in assembly

$seqh = $dbh->prepare("select sum(trim_read_in_contig_stop - trim_read_in_contig_start) as sum_read_length from reads_assembly");
$seqh->execute();
my $sum_read_length  = $seqh->fetchrow_hashref->{sum_read_length};
$insh->execute("assembly", "Number of bases sampled and used in Assembly", commify($sum_read_length));

# Average Coverage

my $average_coverage = $sum_read_length / ($sum_contig_length_all+1);
$insh->execute("assembly", "Average Coverage", trunc_it($average_coverage));


# Total number of reads

$seqh = $dbh->prepare("select count(*) as total_reads from reads_bases");
$seqh->execute();
my $total_reads  = $seqh->fetchrow_hashref->{total_reads};
$insh->execute("assembly", "Total number of reads sequenced", commify($total_reads));


# Total number of reads used in assembly

$seqh = $dbh->prepare("select count(*) as total_reads from reads_assembly");
$seqh->execute();
my $total_reads_in_assem  = $seqh->fetchrow_hashref->{total_reads};
$insh->execute("assembly", "Total number of reads used in assembly", commify($total_reads_in_assem));



#### Reads
if ($debug) {print "Running Reads stats\n";}

# Total reads sequenced
$seqh = $dbh->prepare("select count(*) as total_reads from reads_bases");
$seqh->execute();
my $total_reads  = $seqh->fetchrow_hashref->{total_reads};
$insh->execute("read", "Total Number of Reads Sequenced", commify($total_reads));

if($total_reads > 0)
{

	# Find standard deviation of read length and mean
	$seqh = $dbh->prepare("select length(bases) as read_length from reads_bases");
	my @read_lengths;
	$seqh->execute();
	while(my $row = $seqh->fetchrow_hashref)
	{
		push(@read_lengths, $row->{read_length});
	}
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@read_lengths);

	$insh->execute("read", "Average Read Length &plusmn; stdev", trunc_it($stat->mean) . " &plusmn; " . trunc_it($stat->standard_deviation) . " bp");
	#$insh->execute("read", "Standard Deviation", trunc_it($stat->standard_deviation));

	# Fraction of Reads Paired

	# Fraction of reads assembled
	$seqh = $dbh->prepare("select count(*) as num_assem from reads_assembly");
	$seqh->execute;
	my $num_assem = $seqh->fetchrow_hashref->{num_assem};
	my $frac_assem = ($num_assem / $total_reads) * 100;
	$insh->execute("read", "Fraction of Reads Assembled", percent_it(trunc_it($frac_assem)));


	# Fraction of reads assembled with Partner
	$seqh = $dbh->prepare("select count(*) as num_assem from reads_assembly where read_pair_name is not null");
	$seqh->execute;
	my $num_assem_w_partner = $seqh->fetchrow_hashref->{num_assem};
	my $frac_assem_w_partner = ($num_assem_w_partner / $total_reads) * 100;
	$insh->execute("read", "Fraction of Reads Paired in Assembly", percent_it(trunc_it($frac_assem_w_partner)));


	# Number of Bases used in assembly
	$seqh = $dbh->prepare("select sum(trim_read_in_contig_stop - trim_read_in_contig_start) as num_bases from reads_assembly");
	$seqh->execute();
	my $total_read_bases_used = $seqh->fetchrow_hashref->{num_bases};
	$insh->execute("read", "Number of Bases Used in Assembly", commify($total_read_bases_used) . " bp");

	# Average Shotgun Coverage
	if (!$is_est) 
	{
		$insh->execute("read", "Average Shotgun Coverage", trunc_it($average_coverage) . " fold");
	}
}


#### Contig Stats
if ($debug) {print "Running Contig stats\n";}

if ($is_est) 
{
	$insh->execute("contig", "title", "<center>Contig Size</center></td><td><center>Number</center></td>");
} else {
	$insh->execute("contig", "title", "<center>Contig Size</center></td><td><center>Number</center></td><center>Coverage of $genome_text_size</center>");
}

my $start_size = 512000;
my $current_size = $start_size;
my $num_contig_h = $dbh->prepare("select count(*) as num_contigs from links where contig_length >= ?");
my $size_contigs_h = $dbh->prepare("select sum(contig_length) as num_bases from links where contig_length >= ?");

while($current_size >= 1000)
{
	# Number of contigs with size greater then current_size
	$num_contig_h->execute($current_size);
	$size_contigs_h->execute($current_size);
	my $num_contigs = $num_contig_h->fetchrow_hashref->{num_contigs};
	my $size_coverage = $size_contigs_h->fetchrow_hashref->{num_bases};
	my $perc_coverage = ($size_coverage / $genome_size) * 100;

	if ($is_est) 
	{
		$insh->execute("contig" , "<center>> " . commify($current_size) . " bp</center>" ,"<center>" . link_overview($num_contigs, $current_size, 'contig') . "</center></td>"); 
	} else {
		$insh->execute("contig" , "<center>> " . commify($current_size) . " bp</center>" ,"<center>" . link_overview($num_contigs, $current_size, 'contig') . "</center></td><td><center><b>" . percent_it($perc_coverage) . "</b></center>"); 
	}

	$current_size = $current_size / 2;
}
$num_contig_h->execute(0);
$size_contigs_h->execute(0);
my $num_contigs = $num_contig_h->fetchrow_hashref->{num_contigs};
my $size_coverage = $size_contigs_h->fetchrow_hashref->{num_bases};
my $perc_coverage = ($size_coverage / $genome_size) * 100;
if($is_est) 
{
	$insh->execute("contig", "<center>all contigs</center>" , "<center>" . link_overview($num_contigs, '0', 'contig') . "</center></td>");
} else {
	$insh->execute("contig", "<center>all contigs</center>" , "<center>" . link_overview($num_contigs, '0', 'contig') . "</center></td><td><center><b>" . percent_it($perc_coverage) . "</b></center>");
}
if($num_contigs > 0)
{

	my $avg_length = $size_coverage / $num_contigs;
	my $seqh = $dbh->prepare("select contig_length from links order by contig_length");
	$seqh->execute();
	my $size_array;

	while(my $row = $seqh->fetchrow_hashref)
	{
		push(@{$size_array}, $row->{contig_length});
	}

	my $l50 = l50($size_array);


	my $contig_bases_h = $dbh->prepare("select bases from contigs");
	$contig_bases_h->execute();
	my $bases_array;
	while(my $row = $contig_bases_h->fetchrow_hashref)
	{
		push(@{$bases_array}, $row->{bases});
	}

	my $tot_gc = overall_gc($bases_array) * 100;

	$insh->execute("contig", "header", "The overall average contig length is " . commify(int($avg_length)) . " bp.  50% of all nucleotides lie in contigs of at least " . commify($l50) . " bp.  The overall GC content is " .  percent_it(trunc_it($tot_gc)) . "<p>");

}

#### Supercontig Stats
if ($debug) {print "Running Supercontig stats\n";}

if ($is_est) 
{
	$insh->execute("supercontig", "title", "<center>Supercontig Size</center></td><td><center>Number</center></td><td><center>Isolated Contigs*</center></td>");
} else {
	$insh->execute("supercontig", "title", "<center>Supercontig Size</center></td><td><center>Number</center></td><td><center>Isolated Contigs*</center></td><td><center>Coverage of $genome_text_size</center>");
}
my $start_size = 1024000;
my $current_size = $start_size;
my $num_supercontig_h = $dbh->prepare("select distinct super_id from links where modified_bases_in_super >= ?");
my $size_supercontigs_h = $dbh->prepare("select distinct super_id, modified_bases_in_super from links where modified_bases_in_super >= ?");
my $num_singlet_sc_h = $dbh->prepare("select distinct super_id from links where contigs_in_super = 1 AND modified_bases_in_super >= ?");

while($current_size >= 1000)
{
    # Number of supercontigs with size greater then current_size
    $num_supercontig_h->execute($current_size);
    $size_supercontigs_h->execute($current_size);
	my $size_coverage = 0;
	while(my $row = $size_supercontigs_h->fetchrow_hashref)
	{
		$size_coverage += $row->{modified_bases_in_super};
	}
    my $num_supercontigs = $num_supercontig_h->rows;
    my $perc_coverage = ($size_coverage / $genome_size) * 100;
	$num_singlet_sc_h->execute($current_size);
	my $num_singlets = $num_singlet_sc_h->rows;

	if ($is_est) {
    	$insh->execute("supercontig", "<center>> " . commify($current_size) . " bp</center>" , "<center>" . link_overview($num_supercontigs, $current_size, 'supercontig') . "</center></td><td><center><b>" . link_overview_singlet($num_singlets, $current_size) . "</b></center></td>");
	} else {
    	$insh->execute("supercontig", "<center>> " . commify($current_size) . " bp</center>" , "<center>" . link_overview($num_supercontigs, $current_size, 'supercontig') . "</center></td><td><center><b>" . link_overview_singlet($num_singlets, $current_size) . "</b></center></td><td><center><b>" . percent_it($perc_coverage) . "</b></center>");
	}
    $current_size = $current_size / 2;
}
$num_supercontig_h->execute(0);
$size_supercontigs_h->execute(0);
my $num_supercontigs = $num_supercontig_h->rows;
my $size_coverage = 0;
while(my $row = $size_supercontigs_h->fetchrow_hashref)
{
	$size_coverage += $row->{modified_bases_in_super};
}
my $perc_coverage = ($size_coverage / $genome_size) * 100;
$num_singlet_sc_h->execute(0);
my $num_singlets = $num_singlet_sc_h->rows;

if ($is_est) 
{
	$insh->execute("supercontig", "<center>all supercontigs</center>" , "<center>" . link_overview($num_supercontigs, 0, 'supercontig') . "</center></td><td><center><b>" . link_overview_singlet($num_singlets, 0) . "</b></center></td>");
} else {
	$insh->execute("supercontig", "<center>all supercontigs</center>" , "<center>" . link_overview($num_supercontigs, 0, 'supercontig') . "</center></td><td><center><b>" . link_overview_singlet($num_singlets, 0) . "</b></center></td><td><center><b>" . percent_it($perc_coverage) . "</b></center>");
}

if($num_supercontigs > 0)
{
	my $avg_length = $size_coverage / $num_supercontigs;
	my $seqh = $dbh->prepare("select distinct super_id, modified_bases_in_super from links order by modified_bases_in_super");
	$seqh->execute();
	my $size_array;

	while(my $row = $seqh->fetchrow_hashref)
	{
	        push(@{$size_array}, $row->{modified_bases_in_super});
	}
                                                                                                                                                                                                                                                       
	my $l50 = l50($size_array);

	$insh->execute("supercontig", "header", "The overall average supercontig length is " . commify(int($avg_length)) . " bp.  50% of all nucleotides lie in supercontigs of at least " . commify($l50) . " bp.<p>");
	$insh->execute("supercontig", "footer", "<i>* Isolated contigs are treated as additional supercontigs.  The number given is a subset of the total, not an addition to the total number of supercontigs.</i>");

}

#### EST - Expressed Sequence Tag stats
if ($debug) {print "Running Expressed Sequence Tag stats\n";}

#Estimating Rates and comparing the rates of gene discovery
#and expressed sequence tag (EST) frequencies in EST surveys
#Susko & Roger, 2004, Bioinformatics20(14).
#See also www.math.stats.dal.ca/~tsusko/doc/est_stof.pdf
#Software for estimating and comparing rates of gene discovery and 
#expressed sequence tag (EST) frequencies in EST surveys.

if ($is_est)
{
	#my $reads_super_h = $dbh->prepare("select super_id, count(*) as thecount from reads_assembly, links WHERE reads_assembly.contig_number = links.contig_number GROUP BY links.super_id");
	$setpage->execute("assembly_est.tt");
	my $reads_super_h = $dbh->prepare("select super_id, count( DISTINCT substr(read_name, 1, 13)) as thecount from reads_assembly, links WHERE reads_assembly.contig_number = links.contig_number GROUP BY links.super_id");
	
	my %cov_hash;
	$reads_super_h->execute();
	while (my $row = $reads_super_h->fetchrow_hashref)
	{
		#my $num_reads = $row->{'thecount'};
		#$cov_hash{$num_reads}++;
		$cov_hash{$row->{'thecount'}}++;
	}
	my $nlines = scalar keys %cov_hash;
	my $nlib = 1;
	
	#Create temp file as input to cov_est
	#my $temp_dir = tempdir();
	my $temp_dir = tempdir( CLEANUP => 1);
	#warn "$temp_dir\n";
	my ($cov_est_fh, $cov_est_file) = tempfile( SUFFIX => '.txt', DIR =>$temp_dir);
	open (COV, ">$cov_est_file");
	for my $key (sort {$a <=> $b} (keys %cov_hash))
	{
		my $freq = $cov_hash{$key};
		print COV "$key $freq\n";
	}
	close (COV);
	
	my $str_cov_est = `$cov_est_bin $nlines $nlib < $cov_est_file`;
	
	my @cov_lines = split (/\n/, $str_cov_est);
	#my ($libno, $coverage, $cov_se, $cov_95CI, $cov_95CIplus) = split (/\s/, $cov_lines[4]);
	#my ($libno, $reads_newgene, $reads_newgene_se, $reads_newgene_95CIminus, $reads_newgene_95CIplus) = split (/\s/, $cov_lines[10]);
	my ($libno, $coverage, $cov_se, $cov_95CI) = split (/\s/, $cov_lines[4]);
	my ($libno, $reads_newgene, $reads_newgene_se, $reads_newgene_95CI) = split (/\s/, $cov_lines[10]);
	
	$insh->execute("est", "Library Coverage +- standard error", trunc_it($coverage * 100) ."% +-" . trunc_it($cov_se * 100) );
	$insh->execute("est", "Expected number of reads for a new gene +- standard error", trunc_it($reads_newgene) . " +-" .trunc_it($reads_newgene_se));
	
	$insh->execute("est", "header", "Overall, the EST sequencing has discovered ". trunc_it($coverage * 100) ."% of the expected expressed sequence tags.<p>");
	#my $str_exp_est = `egene_est_single $nlines $nlib ...`



	# Graph Contigs, Supercontigs, Singletons against Number of reads
	$dbh->do("delete from html where variable = 'est_image' AND template = 'default'");
	$inshtml->execute("default", "est_image", '<img src="' . $hist_est . "?organism=$database" . '">');

}
else {
	$setpage->execute("assembly.tt");
	#just in case, delete it anyway!  If someone accidentally ran as EST and can't clean it.
	$dbh->do("delete from html where variable = 'est_datasnapshot' AND template = 'default'");
	$dbh->do("delete from html where variable = 'est_image' AND template = 'default'");
}
## Domain Stats

# Number of domains per algorithm
my $domain_h = $dbh->prepare("select count(*) as num_domains, algorithms.name as algorithm_name, db.name as db_name from algorithms, blast_results br, db, sequence_type st where st.id = br.sequence_type_id AND st.type = 'orf' AND br.algorithm = algorithms.id AND br.db = db.id AND (br.evalue is null OR br.evalue >= 1e-3) AND db.name IN ('interpro', 'Pfam_fs', 'Pfam_ls', 'tmhmm') group by algorithms.name, db.name");

my $distinct_domains = $dbh->prepare("select count(distinct br.accession_number, br.description) as distinct_domains from blast_results br, db, algorithms, sequence_type st WHERE st.id = br.sequence_type_id AND st.type = 'orf' AND algorithms.id = br.algorithm AND br.db = db.id AND (br.evalue is null OR br.evalue >= 1e-3) AND db.name = ?  AND algorithms.name = ?");

$domain_h->execute();

if($domain_h->rows > 0)
{
	$insh->execute("domain", "<center>Database:Algorithm</center>", "</b><center>Number of domains</center></td><td><center>Number of distinct domains</center><b>"); 
	while(my $domain = $domain_h->fetchrow_hashref)
	{
		$distinct_domains->execute($domain->{db_name}, $domain->{algorithm_name});
		my $distinct_result = $distinct_domains->fetchrow_hashref->{distinct_domains};
		$insh->execute("domain", "<center>" . $domain->{db_name} . ":" . $domain->{algorithm_name} . "</center>", '<center>' . commify($domain->{num_domains}) . '</center></b></td><td><b><center>' . $distinct_result. '</center>');
	}
}



# Overview
$insh->execute("overview", "Total Number of Contigs", commify($total_contigs));
$insh->execute("overview", "Total Number of Supercontigs", commify($total_supercontigs));
if (!$is_est) {
	$insh->execute("overview", "Average Shotgun Coverage", trunc_it($average_coverage));
	$insh->execute("overview", "Estimated Closure (of $genome_text_size)", percent_it(($sum_contig_length_all/$genome_size)*100));
}
$insh->execute("overview", "Predicted Open Reading Frames", commify($total_orfs));
if($num_sage_tags > 0)
{
	$insh->execute("overview", "Transcribed ORFs (SAGE detection)", commify($total_orfs_sage) );
	$insh->execute("overview", "Number of SAGE Libraries", commify($num_sage_libraries) );
	$insh->execute("overview", "Number of Unique SAGE Tags ($reduced_text)", commify($num_sage_tags_reduced));
	$insh->execute("overview", "SAGE Tags mapped to ORFs", commify($total_map_orf));
}




# Images

# Histogram of GC content

my $hist_cgi = "/cgi-bin/graph_bar?";
#my $hist_cgi = "/perl/graph_bar?";
my %gc_content;
for(0..100)
{
	$gc_content{$_} = 0;
}

$seqh = $dbh->prepare("select bases from reads_bases");
$seqh->execute();
my $val_string;

$val_string .= "&x_label=%%20GC&y_label=%23%20Reads&title=Distribution%20of%20GC%20Content";

while(my $row = $seqh->fetchrow_hashref)
{
	my $numgc = int(gc($row->{bases})*100);
	$gc_content{$numgc}++;
}
for(0..100)
{
	
	$val_string .= "&vals=" . $_ . ":" . $gc_content{$_};
}


$dbh->do("delete from html where variable = 'readgc_image' AND template = 'default'");
$inshtml->execute("default", "readgc_image", '<img src="' . $hist_cgi . $val_string . '">');


# R value of Primary Sense Tags

my $one_rule_q = $dbh->prepare("select distinct tagid from orftosage where tagtype = 'Primary Sense Tag'");
my $result_q = $dbh->prepare("select library, result from sage_results where tagid = ?");
my $cur_val = 0;
my $max_val = 50;
my $incr = 1;
my $val_string = '';
my $gt_max = 0;

$one_rule_q->execute();
my $libhash;
while(my $row = $one_rule_q->fetchrow_hashref)
{
	$result_q->execute($row->{tagid});
	my $result_array;
	while(my $result = $result_q->fetchrow_hashref)
	{
		push(@{$result_array}, $result->{result});
	}
	$libhash->{$row->{tagid}} = $result_array;
}
my $rval_hash = $mbl->get_rval_hash($libhash);
my $hist_hash;
while(my ($key, $value) = each %{$rval_hash})
{
#	my $adj_val = sprintf("%.0f", $value);
	my $adj_val = int($value);
	$hist_hash->{$adj_val}++;
	if($adj_val > $max_val)
	{
		$gt_max++;
	}
}

$val_string .= "&x_label=R-Value&y_label=%23%20tags&title=R-Value%20per%20Primary%20SAGE%20Tag";
while($cur_val <= $max_val)
{
#	$cur_val = sprintf("%.0f", $cur_val);
	$cur_val = int($cur_val);
	my $num = $hist_hash->{$cur_val};
	if($num == undef)
	{
		$num = 0;
	}
	$val_string .= "&vals=" . $cur_val . ':' . $num;
	$cur_val = $cur_val + $incr;
}


$dbh->do("delete from html where variable = 'rperprimarytag_image' AND template = 'default'");
$inshtml->execute("default", "rperprimarytag_image", '<img src="' . $hist_cgi . $val_string . '">');
$dbh->do("delete from html where variable = 'rperprimarytag_over' AND template = 'default'");
$inshtml->execute("default", "rperprimarytag_over", $gt_max . ' tags with greater then R-Value of 50 are not shown.');


# GC Content of Expressed Orfs
my %orfgc_content;
$seqh = $dbh->prepare("select distinct orfs.sequence from orfs, orftosage where orfs.orfid = orftosage.orfid AND orfs.delete_fg = 'N'");
$seqh->execute();
my $val_string = '';
                                                                                                                                                                                                                                                     
$val_string .= "&x_label=%%20GC&y_label=%23%20ORFs&title=Distribution%20of%20GC%20Content%20of%20Expressed%20ORFs";
                                                                                                                                                                                                                                                     
while(my $row = $seqh->fetchrow_hashref)
{
        my $numgc = int(gc($row->{sequence})*100);
        $orfgc_content{$numgc}++;
}
for(0..100)
{
        $val_string .= "&vals=" . $_ . ":" . $orfgc_content{$_};
}
                                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                                     
$dbh->do("delete from html where variable = 'orfexpressedgc_image' AND template = 'default'");
$inshtml->execute("default", "orfexpressedgc_image", '<img src="' . $hist_cgi . $val_string . '">');


# Codon Usage Bias of Expressed Orfs

my %codon_usage;
$seqh = $dbh->prepare("select distinct orfs.codonusage from orfs, orftosage where orfs.orfid = orftosage.orfid AND orfs.delete_fg = 'N'");
$seqh->execute();
my $val_string = '';
                                                                                                                                                                                                                                                     
$val_string .= "&x_label=Codon%20Usage&y_label=%23%20ORFs&title=Codon%20Usage%20Bias%20of%20Expressed%20ORFs";
                                                                                                                                                                                                                                                     
while(my $row = $seqh->fetchrow_hashref)
{
        my $num = int($row->{codonusage});
        $codon_usage{$num}++;
}
for(20..61)
{
        $val_string .= "&vals=" . $_ . ":" . $codon_usage{$_};
}

$dbh->do("delete from html where variable = 'orfexpressedcodonusage_image' AND template = 'default'");
$inshtml->execute("default", "orfexpressedcodonusage_image", '<img src="' . $hist_cgi . $val_string . '">');


# Genes Per Library

my $seqh = $dbh->prepare("select sln.short_name, count(DISTINCT os.orfid) as expressed_orfs from sage_library_names sln, orftosage os, sage_results sr
			  where sr.tagid = os.tagid
			  AND sln.library = sr.library
			  AND sr.result > 0
			  AND os.tagtype IN ('Primary Sense Tag', 'Alternate Sense Tag')
			  group by sln.short_name order by sln.priority");

$seqh->execute();

$dbh->do("delete from html where variable = 'orfexpressedperlibrary_image' AND template = 'default'");

$val_string = '&x_label=Library&y_label=%23%20Expressed%20ORFs&title=Expressed%20ORFs%20Per%20Library&x_label_skip=1';
while(my $row = $seqh->fetchrow_hashref)
{
	$val_string .= "&vals=" . $row->{short_name} . ':' . $row->{expressed_orfs};
}

$inshtml->execute("default", "orfexpressedperlibrary_image", '<img src="' . $hist_cgi . $val_string . '">');


# Histogram of Size Distribution of ORFs (aa)
my $multip = 10;
my $seqh = $dbh->prepare("select distinct (floor((length(sequence)/3)/$multip))*$multip as seq_len, count(orfid) as num_seqs from orfs where delete_fg = 'N' group by (floor((length(sequence)/3)/$multip))*$multip order by (floor((length(sequence)/3)/$multip))*$multip");

$seqh->execute();

$dbh->do("delete from html where variable = 'orfsequencelength_image' AND template = 'default'");

$val_string = '&x_label=ORF AA Size&y_label=%23%20Number%20ORFs&title=Size%20Distrubution%20(amino%20acid)%20of%20ORFs&x_label_skip=20';
while(my $row = $seqh->fetchrow_hashref)
{
	$val_string .= "&vals=" . $row->{seq_len} . ':' . $row->{num_seqs};
}

$inshtml->execute("default", "orfsequencelength_image", '<img src="' . $hist_cgi . $val_string . '">');


# GC Content of Orfs
my %orfgc_content;
$seqh = $dbh->prepare("select orfs.sequence from orfs where orfs.delete_fg = 'N'");
$seqh->execute();
my $val_string = '';

$val_string .= "&x_label=%%20GC&y_label=%23%20ORFs&title=Distribution%20of%20GC%20Content%20of%20ORFs";

while(my $row = $seqh->fetchrow_hashref)
{
        my $numgc = int(gc($row->{sequence})*100);
        $orfgc_content{$numgc}++;
}
for(0..100)
{
        $val_string .= "&vals=" . $_ . ":" . $orfgc_content{$_};
}

$dbh->do("delete from html where variable = 'orfgc_image' AND template = 'default'");
$inshtml->execute("default", "orfgc_image", '<img src="' . $hist_cgi . $val_string . '">');



# Codon Usage Bias of Orfs

my %codon_usage;
$seqh = $dbh->prepare("select orfs.codonusage from orfs where orfs.delete_fg = 'N'");
$seqh->execute();
my $val_string = '';
                                                                                                                                                                                                                                                     
$val_string .= "&x_label=Codon%20Usage&y_label=%23%20ORFs&title=Codon%20Usage%20Bias%20of%20ORFs";
                                                                                                                                                                                                                                                     
while(my $row = $seqh->fetchrow_hashref)
{
        my $num = int($row->{codonusage});
        $codon_usage{$num}++;
}
for(20..61)
{
        $val_string .= "&vals=" . $_ . ":" . $codon_usage{$_};
}

$dbh->do("delete from html where variable = 'orfcodonusage_image' AND template = 'default'");
$inshtml->execute("default", "orfcodonusage_image", '<img src="' . $hist_cgi . $val_string . '">');



# Overall stats

my $types_h = $dbh->prepare("select distinct type from stats");
$types_h->execute();

while(my $rtype = $types_h->fetchrow_hashref)
{
	$typeq->execute($rtype->{type});
	$gettitle->execute($rtype->{type});
	my $title = '';
	if($gettitle->rows > 0)
	{
		$title = $gettitle->fetchrow_hashref->{value};
	}

	my $snapshot = "<table width=\"80%\" border=3>";
        my $header;
	my $footer;
	if($title ne "")
	{
		$snapshot .= "<tr><td>$title</td></tr>";
	}
	while(my $row = $typeq->fetchrow_hashref)
	{
		if($row->{statistic} eq "footer")
		{
			$footer = "<br>" . $row->{value};
		} elsif($row->{statistic} eq "header")
		{
			$header = $row->{value} . "<p>";
		} else
		{
	       	$snapshot .= "<tr><td>" . $row->{statistic} . "</td><td><b>" . $row->{value} . "</b></td></tr>";
		}
	}
	$snapshot .= "</table>";
                                                                                                                                                                                                                                                      
	$dbh->do("delete from html where variable = '" . $rtype->{type} . "_datasnapshot' AND template = 'default'");

	$snapshot = $header  . $snapshot .  $footer;
	$inshtml->execute("default", $rtype->{type} . "_datasnapshot", $snapshot);
}


print "Done.\n";


sub percent_it {
	my $num = shift;
	return commify((sprintf("%.2f", $num) . "%"));
}

sub trunc_it {
	my $num = shift;
	 return commify((sprintf("%.2f", $num)));
}

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

sub l50
{
        my $list = shift;
        my @array = sort {$a <=> $b} @{$list};
        # First find the sum/2
        my $tot = 0;
        my $l50score = 0;
                                                                                                                             
        foreach (@array)
        {
                $tot += $_;
        }
        $tot = $tot/2;
        # Now go through the array again, and when we reach tot/2, return the value
        my $retval = 0;
        foreach(@array)
        {
                $retval += $_;
                if($retval >= $tot)
                {
                        return $_;
                }
        }
        return 0;
                                                                                                                             
}

sub gc
{
	my $bases = shift;
	my $num_gc = $bases =~ tr/[GCgc]//;
	my $num_at = $bases =~ tr/[ATat]//;
	if($num_gc + $num_at == 0)
	{
		return 0;
	}
	return ($num_gc / ($num_gc + $num_at) );
}

sub link_overview
{
	my $count = shift;
	my $min_size = shift;
	my $type = shift;

	my $tracks;
	return "<a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=$min_size&type=$type\">$count</a>";
}

sub link_overview_singlet
{
        my $count = shift;
        my $min_size = shift;
        return "<a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=$min_size&singlet=Y&type=isolated contigs\">$count</a>";
}

sub overall_gc
{
	my $bases_array = shift;

	my $num_gc = 0;
	my $num_at = 0;
	foreach my $bases (@{$bases_array})
	{
		$num_gc += $bases =~ tr/[GCgc]//;
		$num_at += $bases =~ tr/[ATat]//;
	}
	return ($num_gc / ($num_gc + $num_at) );

}
