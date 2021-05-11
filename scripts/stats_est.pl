#!/usr/bin/perl -w

#########################################
#
# stats_est.pl, updates the statistics for EST / cDNA assemblies
#
# Usage:  stats_est.pl <database>
#
# Author: Susan Huse, shuse@mbl.edu  Date
# 
# Assumptions:
#
# Revisions: 
#		12/14/06 	changed select for "Number of bases used in assembly" to 
#					total number of bases in all trimmed reads.
#
# Programming Notes: adapted from update_stats.pl
#
########################################

use strict;
use Mbl;
use Bio::SeqIO;
use Bio::Seq;
use Statistics::Descriptive;

use Getopt::Long;  
# Connect to the database
use DBI;
use File::Temp qw/ tempfile tempdir /;

my $hist_cgi = "/perl/graph_bar?";
#my $hist_cgi = "/cgi-bin/graph_bar?";
my $hist_est = "/perl/graph_est";
#my $hist_cgi = "/cgi-bin/graph_bar?";
#my $hist_est = "/cgi-bin/graph_est";
my $debug = 1;
my $cov_est_bin = "/xraid/bioware/linux/seqinfo/bin/cov_est";

#my $result_vars = GetOptions (	"organism=s" => \$database,
				#"genome_size=i" => \$genome_size,
				#"genome_text_size=s"=> \$genome_text_size,
				#"is_est=s"=> \$is_est
				#);


if (scalar @ARGV != 1) 
{
	print "
This program will compute EST/cDNA statistics for an mbl gmod database.
Usage: stats_est.pl <organism database>\n";
	exit;
} 
my $database = $ARGV[0];
my $mbl = Mbl::new(undef, $database);
my $dbh = $mbl->dbh();

$dbh->do("DELETE FROM stats");
my $insh = $dbh->prepare("insert into stats (type, statistic, value) VALUES (?, ?, ?)");

my $inshtml = $dbh->prepare("insert into html (template, variable, value) VALUES (?, ?, ?)");

my $typeq = $dbh->prepare("select type, statistic, value from stats where type = ? AND statistic != 'title'");
my $gettitle = $dbh->prepare("select type, statistic, value from stats where type = ? AND statistic = 'title'");
my $setpage = $dbh->prepare("update templates set template_file=? where page_name='assembly'");

my $seqh;

##########################
#
# Summary Statistics
#
##########################
# Total number of assembled cDNAs
$seqh = $dbh->prepare("select count(distinct super_id) as total_assemblies from links where contigs_in_super='1'");
$seqh->execute();
my $total_assemblies  = $seqh->fetchrow_hashref->{total_assemblies};
#$insh->execute("assembly", "Total number of contigs", commify($total_contigs));

#Total number of Isolated ESTs (singletons)
$seqh = $dbh->prepare("select count(*) as aCount from reads_assembly group by contig_number having aCount = 1");
$seqh->execute();
my $total_isolated_ests = $seqh->rows;
my $total_cdna_assemblies = $total_assemblies - $total_isolated_ests;
	

# Total number of incomplete cDNA assemblies
$seqh = $dbh->prepare("select count(distinct super_id) as total_incomplete from links where contigs_in_super<>'1'");
$seqh->execute();
my $total_incomplete_cdnas  = $seqh->fetchrow_hashref->{total_incomplete};
#$insh->execute("assembly", "Total number of incomplete cDNA assemblies", commify($total_incomplete));

warn "Total number of assembled cDNAs: $total_assemblies\n";
warn "Complete cDNA assemblies: $total_cdna_assemblies\n";
warn "Total number of isolated ESTs: $total_isolated_ests\n";
warn "Total number of incomplete cDNAs: $total_incomplete_cdnas.\n";

##############################
#
# Contig/ Assembly Stats
#
##############################
if ($debug) {print "Running Contig / Assembly stats\n";}

# Total number of contigs
$seqh = $dbh->prepare("select count(*) as total_contigs from links");
$seqh->execute();
my $total_contigs  = $seqh->fetchrow_hashref->{total_contigs};
#$insh->execute("assembly", "Total number of contigs", commify($total_contigs));

# Total number of supercontigs
$seqh = $dbh->prepare("select distinct super_id from links");
$seqh->execute();
my $total_supercontigs  = $seqh->rows;
#$insh->execute("assembly", "Total number of supercontigs", commify($total_supercontigs));

# Total Number of bases in contigs
$seqh = $dbh->prepare("select sum(contig_length) as contig_sum from links");
$seqh->execute();
my $sum_contig_length_all  = $seqh->fetchrow_hashref->{contig_sum};
$insh->execute("assembly", "Number of bases in all cDNAs", commify($sum_contig_length_all));

# Number of bases sampled and used in assembly
$seqh = $dbh->prepare("select sum(trim_read_in_contig_stop - trim_read_in_contig_start) as sum_read_length from reads_assembly");
$seqh->execute();
my $sum_read_length  = $seqh->fetchrow_hashref->{sum_read_length};
$insh->execute("assembly", "Number of bases sampled and used for assembly", commify($sum_read_length));

# Average Coverage
my $average_coverage = $sum_read_length / ($sum_contig_length_all+1);
$insh->execute("assembly", "Average Coverage", trunc_it($average_coverage));

# Total number of reads used in assembly
$seqh = $dbh->prepare("select count(*) as total_reads from reads_assembly");
$seqh->execute();
my $total_reads_in_assem  = $seqh->fetchrow_hashref->{total_reads};
$insh->execute("assembly", "Total number of reads used in assembly", commify($total_reads_in_assem));


################################
#
# Reads
#
################################
if ($debug) {print "Running Reads stats\n";}

# Total reads sequenced
$seqh = $dbh->prepare("select count(*) as total_reads from reads_assembly");
$seqh->execute();
my $total_reads  = $seqh->fetchrow_hashref->{total_reads};
print "Total reads = $total_reads\n";

$insh->execute("read", "Total Number of Reads Sequenced", commify($total_reads));

if($total_reads > 0)
{

	# Find standard deviation of read length and mean
	$seqh = $dbh->prepare("select length(bases) as read_length from reads_bases join reads_assembly on reads_assembly.read_name = reads_bases.read_name");
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
	#$seqh = $dbh->prepare("select count(*) as num_assem from reads_assembly");
	#$seqh->execute;
	#my $num_assem = $seqh->fetchrow_hashref->{num_assem};
	my $frac_isolated = ($total_isolated_ests / $total_reads) * 100;
	my $frac_assem = 100 - $frac_isolated;
	$insh->execute("read", "Fraction of Reads as Isolated ESTs", percent_it(trunc_it($frac_isolated)));
	$insh->execute("read", "Fraction of Reads Assembled", percent_it(trunc_it($frac_assem)));


	# Fraction of reads assembled with Partner
	$seqh = $dbh->prepare("select count(*) as num_assem from reads_assembly where read_pair_name is not null");
	$seqh->execute;
	my $num_assem_w_partner = $seqh->fetchrow_hashref->{num_assem};
	my $frac_assem_w_partner = ($num_assem_w_partner / $total_reads) * 100;
	$insh->execute("read", "Fraction of Reads Paired in Assembly", percent_it(trunc_it($frac_assem_w_partner)));


	# Number of Bases used in assembly
	#$seqh = $dbh->prepare("select count(*) as aCount, sum(trim_read_in_contig_stop - trim_read_in_contig_start) as num_bases from reads_assembly group by contig_number having aCount='1'");
	$seqh = $dbh->prepare("select sum(trim_read_in_contig_stop - trim_read_in_contig_start) as num_bases from reads_assembly");
	$seqh->execute();
	my $total_read_bases_used = 0;
	while(my $row = $seqh->fetchrow_hashref)
	{
		$total_read_bases_used += $row->{num_bases};
	}
	$insh->execute("read", "Number of Bases Used in Assembly", commify($total_read_bases_used) . " bp");
	
	$insh->execute("read", "Total Number of Isolated ESTs", $total_isolated_ests);
	$insh->execute("read", "Total Number of cDNA Assemblies", $total_cdna_assemblies);
	$insh->execute("read", "Total Number of Incomplete cDNAs", $total_incomplete_cdnas);

}


#### Supercontig Stats
if ($debug) {print "Running Supercontig stats\n";}

$insh->execute("supercontig", "title", "<center>Assembly Size</center></td><td><center>Number</center></td><td><center>Isolated ESTs*</center></td>");
my $start_size = 4000;
my $current_size = $start_size;
my $num_supercontig_h = $dbh->prepare("select distinct super_id from links where modified_bases_in_super >= ?");
my $size_supercontigs_h = $dbh->prepare("select distinct super_id, modified_bases_in_super from links where modified_bases_in_super >= ?");
my $num_singlet_sc_h = $dbh->prepare("select distinct super_id from links where contigs_in_super = 1 AND modified_bases_in_super >= ?");

while($current_size >= 100)
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
	$num_singlet_sc_h->execute($current_size);
	my $num_singlets = $num_singlet_sc_h->rows;

    $insh->execute("supercontig", "<center>> " . commify($current_size) . " bp</center>" , "<center>" . link_overview($num_supercontigs, $current_size, 'supercontig') . "</center></td><td><center><b>" . link_overview_singlet($num_singlets, $current_size) . "</b></center></td>");
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
$num_singlet_sc_h->execute(0);
my $num_singlets = $num_singlet_sc_h->rows;

$insh->execute("supercontig", "<center>all assemblies</center>" , "<center>" . link_overview($num_supercontigs, 0, 'supercontig') . "</center></td><td><center><b>" . link_overview_singlet($num_singlets, 0) . "</b></center></td>");

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

	$insh->execute("supercontig", "header", "The overall average assembly length is " . commify(int($avg_length)) . " bp.  50% of all nucleotides lie in supercontigs of at least " . commify($l50) . " bp.<p>");
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
	my ($libno1, $coverage, $cov_se, $cov_95CI) = split (/\s/, $cov_lines[4]);
	my ($libno2, $reads_newgene, $reads_newgene_se, $reads_newgene_95CI) = split (/\s/, $cov_lines[10]);
	
	$insh->execute("est", "Library Coverage +- standard error", trunc_it($coverage * 100) ."% +-" . trunc_it($cov_se * 100) );
	$insh->execute("est", "Expected number of reads for a new gene +- standard error", trunc_it($reads_newgene) . " +-" .trunc_it($reads_newgene_se));
	my $estfooter = 'EST statistics adapted from "Susko and Roger. 2004.  Bioinformatics 20(14).  See also <a href = "http://www.mathstat.dal.ca/tsusko/software.cgi">Software for estimating and comparing rates of gene discovery and expressed sequence tag (EST) frequences in EST surveys</a>.';
	$insh->execute("est", "header", "");
	$insh->execute("est", "footer", $estfooter);
	#my $str_exp_est = `egene_est_single $nlines $nlib ...`

	# Graph Contigs, Supercontigs, Singletons against Number of reads
	$dbh->do("delete from html where variable = 'est_image' AND template = 'default'");
	$inshtml->execute("default", "est_image", '<img src="' . $hist_est . "?organism=$database" . '">');


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
#$insh->execute("overview", "Total Number of Contigs", commify($total_contigs));
#$insh->execute("overview", "Total Number of Supercontigs", commify($total_supercontigs));
$insh->execute("overview", "Total Number of Isolated ESTs", commify($total_isolated_ests));
$insh->execute("overview", "Total Number of cDNA Assemblies", commify($total_cdna_assemblies));
$insh->execute("overview", "Total Number of Incomplete cDNAs", commify($total_incomplete_cdnas));


# Images

# Histogram of GC content

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
    my $header = "";
	my $footer = "";
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


#
# Update statistics footer with new date
#
my $daterun = `date`;
my $newfooter = "<i>Statistics last updated $daterun<br>\n Detailed statistics: " . '<a href="?page=assembly">Assembly</a><i>';
my $setfooter = $dbh->prepare("update html set value=? where template='intro' and variable='overview_statistics_footer'");
$setfooter->execute($newfooter);
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
