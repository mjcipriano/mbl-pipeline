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
	warn "Assembly project directory: $ARGV[1] does not exist.  Exiting...\n";
	exit 1;
}
my $projectdir = $ARGV[1];
my $assembly_bases_file = $projectdir . "/assembly.bases";
my $assembly_qual_file = $projectdir . "/assembly.qual";
my $assembly_links_file = $projectdir . "/assembly.links";
my $assembly_reads_file = $projectdir . "/assembly.reads";
my $assembly_unplaced_file = $projectdir . "/assembly.unplaced";
my $reads_bases_file = $projectdir . "/reads.fasta";
my $reads_qual_file = $projectdir . "/reads.qual";
my $reads_xml_file = $projectdir . "/reads.xml";


#foreach my $f ($assembly_bases_file, $assembly_qual_file, $assembly_links_file) {
#foreach my $f ($assembly_bases_file, $assembly_links_file) {
#	if (! -f $f) {
#		warn "Assembly file: $f does not exist.  Exiting...\n";
#		exit 1;
#	}
#}


my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;

my $minimum_gap_length = $ARGV[2];
my $cleanup = 0;
if (scalar @ARGV == 4) 
{
	if ($ARGV[3] eq "cleanup") {$cleanup = 1;}
}
	
my $debug = 0;
#my $insert_database = 1;


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

my $insert_orf = $dbh->prepare('insert into orfs (orfid, orf_name, annotation, annotation_type, source, contig, start, stop, direction, delete_fg, delete_reason, sequence) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');

my $insert_annotation = $dbh->prepare('insert into annotation (userid, orfid, update_dt, annotation, notes, delete_fg, blessed_fg, qualifier, with_from, aspect, object_type, evidence_code, private_fg) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');


# Find a new contig/supercontig for this entry.
my $supercontig_id = get_largest_supercontig() + 1;
my $contig_id = get_largest_contig() + 1;

# Insert into the assembly tables
#if($insert_database)
#{
	#################################
	#
	# Parse Assembly Links (file: assembly.links)
	#
	#################################
	if ($debug)
	{
		print "######################################################\n";
		print "START: assembly.links\n";
	}

	#Insert into links table
	#Assembly.links fields: 
	#0: super_id
	#1: num_bases_in_super
	#2: num_contigs_in_super
	#3: ordinal_num_of_contig_in_supercontig_id
	#4: contig_number
	#5: length_of_contig
	#6: estimated_gap_before_contig
	#7: estimated_gap_after_contig

	if (-f $assembly_links_file) 
	{
		open(LINKS, "$assembly_links_file") or die("Cannot open $assembly_links_file");
		#$dbh->do("delete from links");

		while (<LINKS>)
		{
   		 	my $line = $_;
   		 	my @links_data = split(" ", $line);
	
   		 	if($links_data[0] ne '#super_id') #first line is field names
   		 	{	
		    	$insert_links->execute($links_data[0], $links_data[1], $links_data[2], $links_data[3], $links_data[5], $links_data[6], $links_data[7], $links_data[4]);
   		 	}
		}
		close(LINKS);
	
		# Now determine where contigs are within the supercontig with or without minimum gap length
		my $select_superids = $dbh->prepare("select distinct super_id FROM links");
		$select_superids->execute;
	
		my $contq = "select contig_number, contig_length, ordinal_number, gap_before_contig from links where super_id = ? ORDER BY ordinal_number";
		my $conth = $dbh->prepare("select contig_number, contig_length, ordinal_number, gap_before_contig from links where super_id = ? ORDER BY ordinal_number");
	
		my $updh = $dbh->prepare("update links set modified_contig_start_base = ? where contig_number = ?");
	
		my $updbases = $dbh->prepare("update links set modified_bases_in_super = ? where super_id = ?");
	
		while (my $links_array = $select_superids->fetchrow_hashref)
		{
			# We need to find out the total modified supercontig length And update where the contig starts in the supercontig
			my $start_super_base = 1;
			my $running_end = 0;
	
			$conth->execute($links_array->{super_id});
			while(my $this_contig = $conth->fetchrow_hashref)
			{
				my $this_start = 0;
				if($this_contig->{gap_before_contig} < 0)
				{
					$this_start = $running_end + $minimum_gap_length;
				} else {
					$this_start = $running_end + $this_contig->{gap_before_contig};
				}
	
				$updh->execute($this_start, $this_contig->{contig_number});
				$running_end = $this_start + $this_contig->{contig_length};
			}
	
			$updbases->execute($running_end, $links_array->{super_id});
		}

		# Now without minimum gap length
		my $linksq = '
		select contig_number,
		super_id,
		bases_in_super,
		contigs_in_super,
		ordinal_number,
		contig_length,
		gap_before_contig,
		gap_after_contig,
		contig_start_super_base,
		modified_contig_start_base,
		modified_bases_in_super
		FROM
		links ORDER BY super_id, ordinal_number';

		my $select_links = $dbh->prepare($linksq);
		$select_links->execute;
	
		#my $last_super_id = '';
		my $last_super_id = 0;
		my $super_running_total = 0;

			while(my $links_array = $select_links->fetchrow_hashref)
		{
			if($links_array->{super_id} != $last_super_id)
			{
				$super_running_total = 0;
			}
	
			my $start_val = $super_running_total + $links_array->{gap_before_contig};
			my $end_val = $start_val + $links_array->{contig_length};
			$super_running_total = $end_val;
			$last_super_id = $links_array->{super_id};
	
#			my $update_base_query = "UPDATE links set contig_start_super_base = '" . $start_val . "'WHERE contig_number = '" . $links_array->{contig_number} ."'";
#			my $update_base_result = $dbh->prepare($update_base_query);
			$update_links_contig_start->execute($start_val, $links_array->{contig_number});
		} 
		$update_links_contig_start->finish;

		if ($debug)
		{
			print "END: assembly.links\n";
		}
	}


		#$insert_links->execute($supercontig_id, $length, 1, 1, $length, 0, 0, $contig_id, 1, 1, $length);

	#################################
	#
	# Parse Assembly Bases (file: assembly.bases)
	#
	#################################
	if (-f $assembly_bases_file) 
	{
		if ($debug)
		{
			print "######################################################\n";
			print "START: assembly.bases\n";
		}
	
		my $in_assembly_bases  = Bio::SeqIO->new('-file' => "$assembly_bases_file",
   	                      '-format' => 'Fasta');
	
		#$dbh->do("delete from contigs");
	
		while ( my $seq = $in_assembly_bases->next_seq() )
		{
			my $contig_number = $seq->id;
			if ($contig_number =~ /contig_/)
			{
				$contig_number =~ /(\d+)/;
			}
	
			$insert_contigs->execute($contig_number, $seq->seq);
		}
		$insert_contigs->finish;
	
		if ($debug)
		{
			print "END: reads.bases\n";
		}
	}
	
	#################################
	#
	# Parse Assembly Quality (file: assembly.qual)
	#
	#################################

	if (-f $assembly_qual_file) {
		if ($debug)
		{
			print "######################################################\n";
			print "START: assembly.qual\n";
		}
	
		my  $in_assembly_qual  = Bio::SeqIO->new('-file' => "$assembly_qual_file", '-format'=>'qual');
		
		#$dbh->do("delete from contig_quality");
	
		while ( my $seq = $in_assembly_qual->next_seq() )
		{
			my @quals = @{$seq->qual()};
			my $qual_string = "";
			foreach my $q (@quals)
			{
				$qual_string .= " " . $q;
			}
			$insert_contig_qual->execute($seq->id, $qual_string);
		}
		$insert_contig_qual->finish;
	
		if ($debug)
		{
			print "END: assembly.qual\n";
		}
	}

	#################################
	#
	# Parse XML (file: reads.xml)
	#
	#################################
	
	if (-f $reads_xml_file) {
		if ($debug)
		{
			print "######################################################\n";
			print "START: reads.xml\n";
		}
	
		#$dbh->do("delete from reads");
	
		# instantiate parser
		my $xp = new XML::DOM::Parser();
	
		# parse and create tree
		my $doc = $xp->parsefile($reads_xml_file) or warn ("Can not open $reads_xml_file file!");
	
		# get root node (trace_volume)
		my $root = $doc->getDocumentElement();
	
		# get children (trace)
		my @my_reads = $root->getChildNodes();

		# iterate through trace_volume list
		foreach my $node (@my_reads)
		{
			# if element node
			if ($node->getNodeType() == 1)
			{
				my $trace_name = '';
				my $center_name = '';
				my $plate_id = '';
				my $well_id = '';
				my $template_id = '';
				my $library_id = '';
				my $trace_end = '';
				my $trace_direction = '';
				
				my @children = $node->getChildNodes();
				
				# iterate through child nodes
				foreach my $item (@children)
				{
					# check element name
					if (lc($item->getNodeName) eq "trace_name")
					{
						$trace_name = $item->getFirstChild()->getData;
					}elsif (lc($item->getNodeName) eq "center_name")
					{
						$center_name =  $item->getFirstChild()->getData;
					}elsif (lc($item->getNodeName) eq "plate_id")
					{
						$plate_id = $item->getFirstChild()->getData;
					}elsif (lc($item->getNodeName) eq "well_id")
					{
						$well_id = $item->getFirstChild()->getData;
					}elsif (lc($item->getNodeName) eq "template_id")
					{
						if($item->getFirstChild())
						{
							$template_id = $item->getFirstChild()->getData;
						}
					}elsif (lc($item->getNodeName) eq "library_id")
					{
						if($item->getFirstChild())
						{
							$library_id = $item->getFirstChild()->getData;
						}
					}elsif (lc($item->getNodeName) eq "trace_end")
					{
						$trace_end = $item->getFirstChild()->getData;
					}elsif (lc($item->getNodeName) eq "trace_direction")
					{
						$trace_direction = $item->getFirstChild()->getData;
					}
				}
				$insert_reads_xml->execute($trace_name, $center_name, $plate_id, $well_id, $template_id, $library_id, $trace_end, $trace_direction); 
			}
		}
		$insert_reads_xml->finish;
		if ($debug)
		{
			print "END: reads.xml\n";
		}

	}


	#################################
	#
	# Parse Assembly Reads (file: assembly.reads)
	#
	#################################
	if (-f $assembly_reads_file) {
		if ($debug)
		{
			print "######################################################\n";
			print "START: assembly.reads\n";
		}
	
	
		open(READS, "$assembly_reads_file") or die ("Can not open $assembly_reads_file");
		#$dbh->do("delete from reads_assembly");
	
		#read_name
		#read_status
		#read_len_untrim
		#first_base_of_trim
		#read_len_trim
		#contig_number
		#contig_length
		#trim_read_in_contig_start
		#trim_read_in_contig_stop
		#orientation
		#read_pair_name
		#read_pair_status
		#read_pair_contig_number
		#observed_insert_size
		#given_insert_size
		#given_insert_std_dev
		#observed_inserted_deviation
	
		my $check_read_existence_h = $dbh->prepare("select read_id, read_name from reads where read_name = ?");
		my $insert_into_reads_h = $dbh->prepare("insert into reads (read_id, read_name) values (NULL, ?)");
	
		while (<READS>)
		{
	    	my $line = $_;
			chomp($line);
			$line =~ s/[\r\n]+$//;
	
			my @reads_data = split("\t", $line);
			while(scalar @reads_data < 17)
			{
				push @reads_data, '';
			}
			foreach my $this_var (@reads_data)
			{
				if($this_var eq "")
				{
					$this_var = undef;
				}
			}
	
			$check_read_existence_h->execute($reads_data[0]);
			if($check_read_existence_h->rows == 0)
			{
				$insert_into_reads_h->execute($reads_data[0]);
			}
		
			$insert_reads_assembly->execute($reads_data[0],$reads_data[1],$reads_data[2],$reads_data[3],$reads_data[4],$reads_data[5],$reads_data[6],$reads_data[7],$reads_data[8],$reads_data[9],$reads_data[10],$reads_data[11], $reads_data[12],$reads_data[13],$reads_data[14],$reads_data[15],$reads_data[16]);

		}
		$insert_reads_assembly->finish;
		close(READS);
	
		if ($debug)
		{
			print "END: assembly.reads\n";
		}
	}


	#################################
	#
	# Parse reads bases (file: reads.bases)
	#
	#################################
	if (-f $reads_bases_file) {
		if ($debug)
		{
			print "######################################################\n";
			print "START: reads.bases\n";
		}
	
		my $in_reads_bases  = Bio::SeqIO->new('-file' => "$reads_bases_file",
                         	'-format' => 'Fasta');
	
		#$dbh->do("delete from reads_bases");
		while ( my $seq = $in_reads_bases->next_seq() )
		{
			$insert_reads_bases->execute($seq->id, $seq->seq);
		}
		$insert_reads_bases->finish;
	
		if ($debug)
		{
			print "END: reads.bases\n";
		}
	}
	
	
	#################################
	#
	# Parse reads quality (file: reads.qual)
	#
	#################################
	
	if (-f $reads_qual_file) {
		if ($debug)
		{
			print "######################################################\n";
			print "START: reads.qual\n";
		}
	
		my $in_reads_qual  = Bio::SeqIO->new('-file' => "$reads_qual_file",
                         	'-format' => 'qual');
	
		#$dbh->do("delete from reads_quality");
	
		while ( my $seq = $in_reads_qual->next_seq() )
		{
			my @quals = @{$seq->qual()};
			my $qual_string = "";
			foreach my $q (@quals)
			{
				$qual_string .= " " . $q;
			}
			$insert_reads_qual->execute($seq->id, $qual_string);
		}
		$insert_reads_qual->finish;
		if ($debug)
		{
			print "END: reads.qual\n";
		}
	}


	#################################
	#
	# Parse unplaced (file: assembly.unplaced)
	#
	#################################
	if (-f $assembly_unplaced_file) {
		if ($debug)
		{
			print "######################################################\n";
			print "START: assembly.unplaced\n";
		}
	
		open(UNPLACED, "$assembly_unplaced_file") or warn ("Can not open $assembly_unplaced_file");
		while (<UNPLACED>)
		{
	    	my $line = $_;
	    	my @unplaced_data = split(" ", $line);
	
	    	$update_unplaced_status->execute($unplaced_data[1], $unplaced_data[0]);
		}
	    $update_unplaced_status->finish;
		close(UNPLACED);
		if ($debug)
		{
			print "END: assembly.links\n";
		}
	}

	
#} #END: if (insert_database)

if ($cleanup)
{
	`rm -r $projectdir`
}

exit;

sub get_largest_contig
{
	my $sth = $dbh->prepare("select max(contig_number) as max_id from links");
	$sth->execute();
	#return $sth->fetchrow_hashref->{max_id};

	my $largest_contig = $sth->fetchrow_hashref->{max_id};
	if (! $largest_contig) {$largest_contig = 0;}
	return $largest_contig;
}

sub get_largest_supercontig
{
	my $sth = $dbh->prepare("select max(super_id) as max_id from links");
	$sth->execute();
	#return $sth->fetchrow_hashref->{max_id};

	my $largest_supercontig = $sth->fetchrow_hashref->{max_id};
	if (! $largest_supercontig) {$largest_supercontig = 0;}
	return $largest_supercontig;
}

sub get_max_orfid
{
	my $sth = $dbh->prepare("select max(orfid) as max_id from orfs");
	$sth->execute();
	return $sth->fetchrow_hashref->{max_id};
}

sub print_usage
{
	print "Usage: ./arachne2gmod.pl database projectdirectory min_gap_length [cleanup]\n";
	print "   ex: ./arachne2gmod.pl giardia /xraid/habitat/mydata 100\n\n";
	print "       database - an existing gmod database.\n";
	print "       projecdir - a directory containing at least three arachne files:\n";
	print "             assembly.bases - fasta file containing sequences of bases for the contigs,\n";
	print "             assembly.qual - fasta file containing the sequence of quality scores for the contigs,\n";
	print "             assembly.links - tab-delimited file describing the supercontigs.\n";
	print "       		\nprojecdir may also contain any of these additional files:\n";
	print "             assembly.reads - tab-delimited file describing the placement of reads in the assembly.\n";
	print "             assembly.unplaced - tab-delimited file specifying unplaced reads.\n";
	print "             reads.fasta - fasta file describing the reads.\n";
	print "             reads.qual - fasta file describing the quality scores for the reads.\n";
	print "             reads.xml - xml file describing the reads and their source.\n";
	print "       min_gap_length - an integer value for the minimum gap length.\n";
	print "       cleanup - adding this flag will remove the project directory and all of its contents!\n";
}



