#!/usr/bin/perl

# This script will Compare the orfs to the est sequences. It takes 1 argument (the database) and the gff file of the est sequences position 
# as input and will update the sage set based on the est, orf, and sage tag positions and output a log of those changes and
# Which EST is assigned to which orf to STDOUT

use strict;

use Bio::DB::GFF;

use Mbl;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;


my $debug = 0;

my $ests;

my $orflisth = $dbh->prepare("select orfid, start, stop, direction, contig from orfs where contig = ? AND delete_fg = 'N' AND ( (start between ? AND ?) OR (stop between ? AND ?) ) AND direction = ?");
my $tagmapq = $dbh->prepare("select tagid, id from tagmap where contig = ? AND stop <= ? AND stop >= ? AND tagid = ? limit 1");

my $ins_orftosage = $dbh->prepare("insert into orftosage (orfid, tagid, tagtype, unique_genome_fg, unique_trans_fg, tagmapid, manual_fg, assignment_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
my $upd_orftosage = $dbh->prepare("update orftosage set tagtype = 'Alternate Sense Tag', assignment_type = 'EST Change' where tagid = ?");
my $del_orftosage = $dbh->prepare("delete from orftosage where tagid = ?");
my $del_primary = $dbh->prepare("delete from orftosage where orfid = ? AND tagtype = 'Primary Sense Tag' AND (assignment_type != 'EST' OR assignment_type is NULL)");

while(<>)
{
        if($_ =~ /^\#/)
        {
                next;
        }

        my @line = split("\t", $_);
        chomp(@line);
        my $attribhash;
        $attribhash->{contig} = $line[0];
	$attribhash->{source} = $line[1];
	$attribhash->{type} = $line[2];
        $attribhash->{start} = $line[3];
        $attribhash->{stop} = $line[4];
        $attribhash->{direction} = $line[6];
        $attribhash->{attribs} = $line[8];
         ($attribhash->{group_class},$attribhash->{group_name},$attribhash->{target_start},$attribhash->{target_stop},$attribhash->{attributes}) = Bio::DB::GFF->split_group($attribhash->{attribs},0);
	if($debug > 0)
	{
		print 	"Group Name\t$attribhash->{group_name}\n" ;
	}
	
	if($debug > 3)
	{
		print	"Group Class\t$attribhash->{group_class}\n" .
			"Reference\t$attribhash->{contig}\n" .
			"Source\t$attribhash->{source}\n" .
			"Type\t$attribhash->{type}\n" . 
			"Start\t$attribhash->{start}\n".
			"Stop\t$attribhash->{stop}\n" .
			"Direction\t$attribhash->{direction}\n" .
			"Target Start\t$attribhash->{target_start}\n" .
			"Target Stop\t$attribhash->{target_stop}\n";
	}
        foreach my $att (@{$attribhash->{attributes}})
        {
                my ($key, $val) = @$att;
                if($debug > 3)
                {
                        print join("\t", $key, $val) . "\n";
                }
                $attribhash->{$key} = $val;
        }

	# If this is a match line, then we can use it, otherwise move on.

	if($attribhash->{type} eq "match")
	{
		$ests->{$attribhash->{group_name}} = $attribhash;
	}

}

# Now all data is loaded

my $clones_examined;
my $clone2orf;
my $singlets = 0;

while( my ($key, $val) = each(%$ests) )
{
	# If we already processed this clone as a pair, do not process it again
	if($clones_examined->{$key})
	{
	#	print "$key already examined\n";
		next;
	}
	my ($clone_name) = $key =~ /(.+)\.[bg]/;
	
	my $fwd_clone_name = $clone_name . ".b1.1";
	my $rev_clone_name = $clone_name . ".g1.1";
	$clones_examined->{$fwd_clone_name} = 1;
	$clones_examined->{$rev_clone_name} = 1;
	
	my $fwd_clone = $ests->{$fwd_clone_name};
	my $rev_clone = $ests->{$rev_clone_name};

	if($fwd_clone eq undef || $rev_clone eq undef)
	{
	#	print $clone_name . " is not paired, error!\n";
		next;
	}

	# If the fwd clone and reverse clone are on different contigs
	if($fwd_clone->{contig} ne $rev_clone->{contig})
	{
		next;
	}

	# If the fwd and reverse clonse are more then 30kb apart
	#print "Examining clones $fwd_clone_name and $rev_clone_name\n";

	my $min = $mbl->get_min($fwd_clone->{start}, $rev_clone->{start}, $fwd_clone->{stop}, $rev_clone->{stop});
	my $max = $mbl->get_max($fwd_clone->{start}, $rev_clone->{start},$fwd_clone->{stop}, $rev_clone->{stop});
	#print " Minimum $min\n";
	#print " Maximum $max\n";

	if( ($max - $min) > 20000)
	{
		next;
	}
	
	# Find if one of the clones is polyadenlylated and which one is.
	my $gene_dir;
	if( ($fwd_clone->{Polyadenylation} eq "Yes" && $fwd_clone->{direction} eq "+") || ($rev_clone->{Polyadenylation} eq "Yes" && $rev_clone->{direction} eq "+") )
	{
		$gene_dir = "-";
	} elsif( ($fwd_clone->{Polyadenylation} eq "Yes" && $fwd_clone->{direction} eq "-") || ($rev_clone->{Polyadenylation} eq "Yes" && $rev_clone->{direction} eq "-") )
	{
		$gene_dir = "+";
	} else
	{
		$gene_dir = "Unknown";
	}
#	print " $gene_dir\n";

	if($gene_dir eq "Unknown")
	{
		next;
	}
	# Get orfs that overlap this est set and 
	$orflisth->execute($fwd_clone->{contig}, $min, $max, $min, $max, $gene_dir);
	my $num_overlapping = $orflisth->rows();
#	print " $num_overlapping Overlapping orfs\n";

	if($num_overlapping == 1)
	{
		$singlets++;
	}
	my $point_hash;
	my $min_5utr = 10000000000000000;
	my $min_orfid;
	while(my $row = $orflisth->fetchrow_hashref)
	{
		my $orfdetail = $mbl->get_orf_attributes_hash($row->{orfid});

		# Get hypothetical utr's based on est's
		my $utr_5;
		my $utr_3;
		if($orfdetail->{direction} eq "+")
		{
			$utr_5 = $orfdetail->{start} - $min;
			$utr_3 = $max - $orfdetail->{stop};
		} else
		{
			$utr_5 = $max - $orfdetail->{stop};
			$utr_3 = $orfdetail->{start} - $min;
		}
#		print "\t$orfdetail->{orfid}\t$utr_5\t$utr_3\n";

		if($orfdetail->{stop} - $orfdetail->{start} > 100)
		{
			$point_hash->{$orfdetail->{orfid}}++;
		}
		if($utr_3 > 0)
		{
			$point_hash->{$orfdetail->{orfid}}++;
		}
		if($min_5utr > $utr_5)
		{
			$min_orfid = $orfdetail->{orfid};
			$min_5utr = $utr_5;
		}
		
	}
	# Now make a call as to which orf this est maps on to.
	# 1 point for the minimum 5' utr and 1 point for a 3' utr that is positive and one point for being an orf greater then 100bp's
	$point_hash->{$min_orfid}++;

#	print "\n";
	my $max_orf = 0;
	my $max_points = 0;
	while(my ($key, $val) = each(%{$point_hash}))
	{
		if($val > $max_points)
		{
			$max_points = $val;
			$max_orf = $key;
		}
		if($debug > 4)
		{
			print " $key has $val points.\n";
		}
	}
	if($debug > 4)
	{
		print " ORF $max_orf won with $max_points\n";
	}
	
	my $est_orf = $mbl->get_orf_attributes_hash($max_orf);
	my $orf_sage_tag_ref = $mbl->sage_orf_tagtypes_ref($max_orf, 'Primary Sense Tag', 15)->fetchrow_hashref;
	my $orf_sage_tag = $orf_sage_tag_ref->{tagid};
	
	my $match = "false";

	if($fwd_clone->{"Tag-ID"} eq "" && $rev_clone->{"Tag-ID"} ne "")
	{
		$fwd_clone->{"Tag-ID"} = $rev_clone->{"Tag-ID"};
	} 
	if($fwd_clone->{"Tag-ID"} eq "0" && $rev_clone->{"Tag-ID"} > 0)
	{
		$fwd_clone->{"Tag-ID"} = $rev_clone->{"Tag-ID"};
	}

	if($rev_clone->{"Tag-ID"} eq "0" && $fwd_clone->{"Tag-ID"} > 0)
	{
		$rev_clone->{"Tag-ID"} = $fwd_clone->{"Tag-ID"};
	}

	if($fwd_clone->{"Tag-ID"} eq $orf_sage_tag )
	{
		$match = "true";
	} elsif($fwd_clone->{"Tag-ID"} eq "0")
	{
		$match = "undef";
	}elsif($orf_sage_tag eq undef)
	{
		$match = "new";
	}
	if($debug > 4)
	{
		print "Match type is $match\n";
	}

	if($est_orf)
	{
		print "$clone_name\t" . $fwd_clone->{"Tag-ID"} . "\t$max_orf\t$orf_sage_tag\t$match\n";
		
		# now if it is false or new, change the primary tag for this orf to the one listed.
		if($match eq 'new')
		{
			# Find the sagetagid
			$tagmapq->execute($fwd_clone->{contig}, $max, $min, $fwd_clone->{"Tag-ID"});
			my $tagmapid_row = $tagmapq->fetchrow_hashref;
			my $tagmapid;
			if($tagmapid_row)
			{
				$tagmapid = $tagmapid_row->{id};
				$ins_orftosage->execute($max_orf, $fwd_clone->{"Tag-ID"}, 'Primary Sense Tag', 0, 1, $tagmapid, undef, 'EST');
			} else
			{
				print "Tagid " . $fwd_clone->{"Tag-ID"} . " not found in area around orf " . $max_orf . "\n";
			}
		} elsif($match eq 'false')
		{
			# We have assigned the tag previously to the wrong orf. Remove the old tag from the orftosage table and set this one

			
			# Find the sagetagid
			$tagmapq->execute($fwd_clone->{contig}, $max, $min, $fwd_clone->{"Tag-ID"});
			my $tagmapid_row = $tagmapq->fetchrow_hashref;
			my $tagmapid;
			if($tagmapid_row)
			{
				$del_primary->execute($max_orf);
				$del_orftosage->execute($fwd_clone->{"Tag-ID"});
				$tagmapid = $tagmapid_row->{id};
				$ins_orftosage->execute($max_orf, $fwd_clone->{"Tag-ID"}, 'Primary Sense Tag', 0, 1, $tagmapid, undef, 'EST');
			} else
			{
				print "Tagid " . $fwd_clone->{"Tag-ID"} . " not found in area around orf " . $max_orf . "\n";
			}
		}
	}

	
#	print "\n";
}


#print "\n$singlets Singlets\n\n"

