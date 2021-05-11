#!/usr/bin/perl -w
use strict;

# This script will import files in bambus format into our mbl gmod database and will create all of the necessary pre pipeline information
# Usage: ./amosgmod.pl database projectdir


use Bio::SeqIO;
use Mbl;
use CGI qw(:all);
use CGI::Pretty;
use DBI;


my $organism;
my $bambus_out_xml;
my $contig_file;
my $ace_file;
my $minimum_gap_length = 100;
my $help = 0;
my $no_delete = 0;
my %contig_size;


use Getopt::Long;

		GetOptions(     "organism=s"		=>\$organism,
                                "bambus_xml=s"       	=>\$bambus_out_xml,
                                "contig_file=s"		=>\$contig_file,
				"ace_file=s"		=>\$ace_file,
				"minimum_gap_length=i"  =>\$minimum_gap_length,
				"no_delete"		=>\$no_delete,
				"help"			=>\$help
                        );				

if(!defined($organism) || $help )
{

	print "

Options:

--organism		Name of the database to import your data into
--bambus_xml		The bambus.out.xml file which has the scaffolding data
--contig_file		The contig file which has the reads assembly information (or ace_file can be used instead)
--ace_file		The ace file which has the reads assembly information (or contig_file can be used instead) --not yet
--minimum_gap_length	The minimum gap length between contigs in a scaffold
--assembly_fasta	A fasta file of the contigs (can be used if no assembly data is available) --not yet
--assembly_qual		A fasta file of the quality of the assembly --not yet
--reads_fasta		A fasta file of the reads (optional) --not yet
--reads_qual		A fasta file of the reads quality (optional) --not yet
--no_delete		Do not delete the assembly information from the database before inserting the new data (default is to delete)

	";

	exit;
}


my $mbl = Mbl::new(undef, $organism);

my $dbh = $mbl->dbh;

if(!defined($minimum_gap_length))
{
	$minimum_gap_length = 100;
}

my $debug = 0;
#my $insert_database = 1;


#Create dbh prepare statements

my $insert_read = $dbh->prepare('insert into `reads` (read_name) values (?)');
my $insert_reads_bases = $dbh->prepare('insert into reads_bases (read_name, bases) VALUES (?, ?)');
my $insert_reads_qual = $dbh->prepare("insert into reads_quality (read_name, quality) VALUES (?, ?)");
my $insert_reads_assembly = $dbh->prepare('insert into reads_assembly (read_name, read_status, read_len_untrim, first_base_of_trim, read_len_trim, contig_number, contig_length, trim_read_in_contig_start, trim_read_in_contig_stop, orientation, read_pair_name, read_pair_status, read_pair_contig_number, observed_insert_size, given_insert_size, given_insert_std_dev, observed_inserted_deviation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');


my $insert_links = $dbh->prepare('insert into links (super_id, bases_in_super, contigs_in_super, ordinal_number, contig_length, gap_before_contig, gap_after_contig, contig_number, contig_start_super_base, modified_contig_start_base, modified_bases_in_super) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
my $updbases = $dbh->prepare("update links set modified_bases_in_super = ?, bases_in_super = ? where super_id = ?");

my $insert_contigs = $dbh->prepare('insert into contigs (contig_number, bases) values (?, ?)');
my $update_links_contig_start = $dbh->prepare('UPDATE links set contig_start_super_base =  ? WHERE contig_number = ?' );
my $insert_contig_qual = $dbh->prepare("insert into contig_quality (contig_number, quality) VALUES (?, ?)");
my $update_unplaced_status = $dbh->prepare("update `reads` set status = ? where read_name = ?");
my $upnumcontig = $dbh->prepare("update links set contigs_in_super = ? where super_id = ?");
my $contig_sizes_sth = $dbh->prepare("select contig_number, length(bases) as length_contig from contigs");


# First import from assembly



if(defined($contig_file))
{
	import_contig_file($contig_file);
}

# Get all contig sizes


if(defined($bambus_out_xml))
{
	process_xml($bambus_out_xml);
}


sub process_xml
{
	my $xml_file = shift;

	# We expect to know the sizes of contigs for this part to work. Find them from the database.
	
	$contig_sizes_sth->execute();
	while(my $con_row = $contig_sizes_sth->fetchrow_hashref)
	{
		my ($this_contig_id) = $con_row->{contig_number} =~ /contig_(\d+)/;
		$contig_size{$this_contig_id} = $con_row->{length_contig};

	}

	if(! -e $xml_file)
	{
		die("No file: $xml_file found!");
	}

	open(BAMBUS, $xml_file);


	if(!$no_delete)
	{
		$dbh->do("delete from links");
	}


	my $cur_scaffold_id = 0;
	my $cur_contig_id = 0;
	my $cur_offset = 0;
	my $cur_dir = ''; # BE forward EB reverse
	my $contig_line = '';
	my %scaffold_ids;
	my @sorted_scaffolds = ();


	# Scaffolds will contain a hashref of contigs. Key is the scaffold id.
	# Contig hashref will contain "offset(x), dir"
	my %scaffolds;
	while(<BAMBUS>)
	{

		my $line = $_;
		chomp($line);
		if($line =~ /\<UNUSED\>/ )
		{
			last;
		}
		if($line =~ /^\<SCAFFOLD\ ID/)
		{
			$cur_scaffold_id = create_scaff_id($line, \%scaffold_ids);
			push(@sorted_scaffolds, $cur_scaffold_id);
			$scaffold_ids{$cur_scaffold_id} = 1;

		}
		if($line =~ /^\<CONTIG\ ID/)
		{
			($cur_contig_id) = $line =~ /contig_.+_[cs](\d+)/;
			$contig_line = $line;
		}

		if($line =~ /\ \ X\ \=/)
		{
			($cur_offset) = $line =~ /\ \ X\ \=\ \"(\d+)\"/;
			if($cur_offset == 0)
			{
				$cur_offset = 1;
			}
		}

		if($line =~ /\ \ ORI\ \=/)
		{
			($cur_dir) = $line =~ /\ \ ORI\ \=\ \"(\w+)\"/;
		}
		
		if($line =~ /\<\/CONTIG\>/)
		{
			# Find gap before contig
			if(!exists($contig_size{$cur_contig_id}))
			{
				warn("NO CONTIG SIZE FOR " . $contig_line );
			}
#			print join("\t", $cur_scaffold_id, $cur_contig_id, $cur_dir, $cur_offset, $contig_size{$cur_contig_id} ) . "\n";
			my %contigrec;
			$contigrec{dir} = $cur_dir;
			$contigrec{offset} = $cur_offset;
			$contigrec{id} = $cur_contig_id;
			$contigrec{scaffold_id} = $cur_scaffold_id;
			$contigrec{length} = $contig_size{$cur_contig_id};

			if($cur_dir eq 'EB')
			{
				# If it is reversed, we need to change the offset
				$contigrec{offset} = $contigrec{offset} - $contigrec{length};
			}
			$scaffolds{$cur_scaffold_id}->{$cur_contig_id} = \%contigrec;
			# Do Insert
			
		}
	}
	print "Done reading file\n";

	foreach my $scaffold_id (@sorted_scaffolds)
	{
		my $running_start = 0;
		my $running_end = 0;
		my $act_start = 0;
		my $act_end = 0;
		my $last_contig_id = 0;
		my $ordinal_number = 0;

		my $contigs = $scaffolds{$scaffold_id};
		my @sorted_contigs = sort { $contigs->{$a}->{offset} <=> $contigs->{$b}->{offset} } keys %{$contigs};
		my $num_contigs = scalar @sorted_contigs;

		foreach my $contig_id (@sorted_contigs)
		{
			my $contigrec = $contigs->{$contig_id};
			my $this_diff = 0;
			$ordinal_number++;
			if($last_contig_id != 0)
			{
				$this_diff = $contigs->{$contig_id}->{offset} - ($contigs->{$last_contig_id}->{offset} + $contigs->{$last_contig_id}->{length}) ;
			}
			if($running_start == 0)
			{
				$running_start = 1;
			} elsif($this_diff > $minimum_gap_length)
			{
				$running_start = $running_end + $this_diff;
			} else
			{
				$running_start = $running_end + $minimum_gap_length;
			}

			if($act_start == 0)
			{
				$act_start = 1;
			} else
			{
				$act_start = $act_end + $this_diff;
			}

			$running_end = $running_start + $contigrec->{length} - 1;
			$act_end = $act_start + $contigrec->{length} - 1;
			print join("\t", $scaffold_id, $ordinal_number, $contig_id, $contigrec->{offset}, $contigrec->{length}, $contigrec->{dir}, $running_start, $running_end, $this_diff) . "\n";
			if($contigrec->{dir} eq 'EB')
			{
				flip_contig($cur_contig_id, $contig_size{$cur_contig_id});
			}
			$insert_links->execute($scaffold_id, undef, $num_contigs, $ordinal_number, $contigrec->{length}, $this_diff, undef, $contig_id, $act_start, $running_start, undef);
			$last_contig_id = $contig_id;

		}
		# Now update all the scaffold contigs to be the running_end for total bases
		$updbases->execute($running_end, $act_end, $scaffold_id);

	}


}

sub create_scaff_id
{
	my $scaff_line = shift;
	my $scaffold_ids = shift;

	my $scaff_id;

	if($scaff_line =~ /scaff_\d+_\d+/)
	{
		# This is an untangled scaffold.
		my ($tmp1, $tmp2) = $scaff_line =~ /scaff_(\d+)_(\d+)/;
		$scaff_id = $tmp1 . $tmp2;
		while(exists($scaffold_ids->{$scaff_id}))
		{
			$tmp2 = "0" . $tmp2;
			$scaff_id = $tmp1 . $tmp2;
		}
	} else
	{
		($scaff_id) = $scaff_line =~ /scaff_(\d+)/;
	}
	return $scaff_id;

}
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


sub flip_contig
{
	my $contig_number = shift;
	my $this_contig_size = shift;

	my $contig_bases_sth = $dbh->prepare("select bases from contigs where contig_number = ?");
	my $update_contig_sth = $dbh->prepare("update contigs set bases = ? where contig_number = ?");
	my $update_read_assembly_all_sth = $dbh->prepare("update reads_assembly set trim_read_in_contig_start = (? - trim_read_in_contig_start +1), trim_read_in_contig_stop = (? - trim_read_in_contig_stop + 1) where contig_number = ?");
	my $update_read_assembly_dir_1 = $dbh->prepare("update reads_assembly set orientation = 0 where orientation = '-' AND contig_number = ?");
	my $update_read_assembly_dir_2 = $dbh->prepare("update reads_assembly set orientation = '-' where orientation = '+' AND contig_number = ?");
	my $update_read_assembly_dir_3 = $dbh->prepare("update reads_assembly set orientation = '+' where orientation = 0 AND contig_number = ?");

	$contig_bases_sth->execute($contig_number);
	if($contig_bases_sth->rows > 0)
	{
		my $bases = $contig_bases_sth->fetchrow_hashref->{bases};
		my $seq = Bio::Seq->new(-seq=>$bases, -display_id=>$contig_number);
		my $rev_seq = $seq->revcom()->seq();
		$update_contig_sth->execute($rev_seq, $contig_number);
	}

	$update_read_assembly_all_sth->execute($this_contig_size, $this_contig_size, $contig_number);
	$update_read_assembly_dir_1->execute($contig_number);
	$update_read_assembly_dir_2->execute($contig_number);
	$update_read_assembly_dir_3->execute($contig_number);
}



sub import_contig_file
{
	my $contig_file = shift;

	my $sequence = '';
	my $last_type = '';

	my ($read_name, $read_length, $rc, $read_start, $read_stop, $contig_start, $contig_stop);
	my ($contig_name, $num_reads, $this_contig_size);

	my %readinfo;
	my %contiginfo;
	my $first = 0;

	if(! -e $contig_file)
	{
		die("No file: $contig_file found!");
	}

	if(!$no_delete)
	{
		$dbh->do("delete from contigs");
		$dbh->do("delete from `reads`");
		$dbh->do("delete from reads_assembly");
		$dbh->do("delete from reads_bases");
	}

	open(CONTIGFILE, $contig_file);

	while(<CONTIGFILE>)
	{
		my $line = $_;
		chomp($line);

		if($line =~ /\#\#/ ) # this is a contig
		{
			$last_type = 'contig';
			
			($contig_name, $num_reads, $this_contig_size) = $line =~ /^\#\#(\S+) (\d+) (\d+) bases/;
			my ($this_contig_num) = $contig_name =~ /(\d+)$/;	
			$contig_size{$this_contig_num} = $this_contig_size;
	#		print join(" ", $contig_name, $num_reads, $this_contig_size) . "\n";
			my %thisrec;
			$thisrec{sequence} = '';
			$thisrec{num_reads} = $num_reads;
			$thisrec{contig_id} = $this_contig_num;
			$thisrec{contig_size} = $this_contig_size;
			$contiginfo{$contig_name} = \%thisrec;

		
		} elsif($line =~ /\#/) # This is a read line
		{
			$last_type = 'read';
			($read_name, $read_length, $rc, $read_start, $read_stop, $contig_start, $contig_stop) = $line =~
				/^\#(\S+)\(\d+\) \[(.*)\] (\d+) bases, \d+ checksum\. \{(\d+) (\d+)\} \<(\d+) (\d+)\>/;

	#		print join(" ", $read_name, $read_length, $rc, $read_start, $read_stop, $contig_start, $contig_stop) . "\n";
			my $contig_dir = '+';
			if($contig_start > $contig_stop)
			{
				my $t = $contig_stop;
				$contig_stop = $contig_start;
				$contig_start = $t;
				$contig_dir = '-';
			}

			my %thisrec;
			$thisrec{sequence} = '';
			$thisrec{read_length} = $read_length;
			$thisrec{rc} = $rc;
			$thisrec{read_start} = $read_start - 1;
			$thisrec{read_stop} = $read_stop - 1;
			$thisrec{contig_start} = $contig_start;
			$thisrec{contig_stop} = $contig_stop;
			$thisrec{contig} = $contig_name;
			$thisrec{dir} = $contig_dir;
			$readinfo{$read_name} = \%thisrec;
		} else
		{
			if($last_type eq 'contig')
			{
				$contiginfo{$contig_name}->{sequence} .= $line;
			} elsif($last_type eq 'read')
			{
				$readinfo{$read_name}->{sequence} .= $line;
			}
		}

	}


	while(my ($this_contig_name, $contig_rec) = each(%contiginfo))
	{
		my ($contig_num) = $this_contig_name =~ /(\d+)$/;
		$insert_contigs->execute('contig_' . $contig_num, scrub_seq($contig_rec->{sequence}));
		print $this_contig_name . "\n";
	}


	while(my ($read_name, $read_rec) = each(%readinfo))
	{
		my $read_contig_name = $read_rec->{contig};
		my ($read_contig_num) = $read_contig_name =~ /(\d+)$/;

		$insert_read->execute($read_name);
		$insert_reads_bases->execute($read_name, scrub_seq($read_rec->{sequence}));
		$insert_reads_assembly->execute(
				$read_name, 
				undef, 
				$read_rec->{read_length}, 
				1, 
				$read_rec->{read_length}, 
				$read_contig_num, 
				$contiginfo{$read_rec->{contig}}->{contig_size}, 
				$read_rec->{contig_start}, 
				$read_rec->{contig_stop}, 
				$read_rec->{dir}, 
				undef, undef, undef, undef, undef,undef, undef
				);
		print join("\t", $read_name,
				$read_rec->{read_length}, 
				$read_contig_num, 
				$contiginfo{$read_rec->{contig}}->{contig_size}, 
				$read_rec->{contig_start}, 
				$read_rec->{contig_stop}, 
				$read_rec->{dir},
				$read_contig_name) . "\n";
 
	}

}
sub scrub_seq
{
	my $seq = shift;
	$seq =~ s/\-//g;
	return $seq;
	
}

