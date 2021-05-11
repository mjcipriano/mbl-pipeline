#!/usr/bin/perl


use strict;

use Bio::DB::GFF;

use Mbl;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;


my $debug = 0;

my $ests;

my %orfhash;

my $orflisth = $dbh->prepare("select orfid, start, stop, direction, contig from orfs where contig = ? AND delete_fg = 'N' AND ( (start between ? AND ?) OR (stop between ? AND ?) ) AND direction = ?");


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
open(UTR, ">", "est_utr.fasta");
print join("\t", "ORFID", "EST_CLONE", "ORF_SIZE", "EST_SIZE", "UTR_SIZE") . "\n";

while( my ($key, $val) = each(%$ests) )
{
	# If we already processed this clone as a pair, do not process it again
	if($clones_examined->{$key})
	{
		if($debug > 5)
		{
			print "$key already examined\n";
		}
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
		if($debug > 5)
		{
			print $clone_name . " is not paired, error!\n";
		}
		next;
	}

	# If the fwd clone and reverse clone are on different contigs
	if($fwd_clone->{contig} ne $rev_clone->{contig})
	{
		next;
	}

	# If the fwd and reverse clones are more then 30kb apart

	if($debug > 4)
	{
		print "Examining clones $fwd_clone_name and $rev_clone_name\n";
	}

	my $min = $mbl->get_min($fwd_clone->{start}, $rev_clone->{start}, $fwd_clone->{stop}, $rev_clone->{stop});
	my $max = $mbl->get_max($fwd_clone->{start}, $rev_clone->{start},$fwd_clone->{stop}, $rev_clone->{stop});
	if($debug > 4)
	{
		print " Minimum $min\n";
		print " Maximum $max\n";
	}

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
	if($debug > 4)
	{
		print " $gene_dir\n";
	}

	if($gene_dir eq "Unknown")
	{
		next;
	}
	# Get orfs that overlap this est set and 
	$orflisth->execute($fwd_clone->{contig}, $min, $max, $min, $max, $gene_dir);
	my $num_overlapping = $orflisth->rows();

	if($debug > 4)
	{
		print " $num_overlapping Overlapping orfs\n";
	}

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
		if($debug > 4)
		{
			print "\nORF:" . $orfdetail->{orfid} . "\t5UTR:$utr_5\t3UTR:$utr_3\tPoints:" . $point_hash->{$orfdetail->{orfid}} . "\n";
		}

		
	}
	# Now make a call as to which orf this est maps on to.
	# 1 point for the minimum 5' utr and 1 point for a 3' utr that is positive and one point for being an orf greater then 100bp's
	$point_hash->{$min_orfid}++;


	if($debug > 4)
	{
		print "Minimum 5'UTR - ORF:$min_orfid\n";
	}
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

	open(ESTLARGE, ">", "est_large.fasta");
	# Find all of the areas that are larger then largesize
	my $large_size = 3500;
	if( ($max - $min) >= $large_size)
	{
		my $seq = $mbl->get_region($fwd_clone->{contig}, $min, ($max - $min + 1) );
		print ESTLARGE ">" . $clone_name . " size:" . $max - $min + 1 . " contig:" . $fwd_clone->{contig} . ":$min..$max\n" . $seq . "\n";
	}

	# Now get the 3'UTR
	my $prime3_distance;

	if($est_orf && !$orfhash{$est_orf->{orfid}} )
	{
		if($est_orf->{direction} eq "+")
		{
			$prime3_distance = $max - $est_orf->{stop} + 1;
			print join("\t", $est_orf->{orfid}, $clone_name, ($est_orf->{stop} - $est_orf->{start} + 1), ($max - $min + 1), $prime3_distance) . "\n";
			if($prime3_distance > 0)
			{
				print UTR ">" . $est_orf->{orfid} . "_" . $clone_name . "\n" . $mbl->get_region($est_orf->{contig}, $est_orf->{stop}, $prime3_distance) . "\n";
				if($prime3_distance > $orfhash{$est_orf->{orfid}})
				{
					$orfhash{$est_orf->{orfid}} = $prime3_distance;
				}
			}
		} else
		{
			$prime3_distance = $est_orf->{start} - $min + 1;
			print join("\t", $est_orf->{orfid}, $clone_name, ($est_orf->{stop} - $est_orf->{start} + 1), ($max - $min + 1), $prime3_distance) . "\n";
			if($prime3_distance > 0)
			{
				print UTR ">" . $est_orf->{orfid} . "_" . $clone_name . "\n" . $mbl->reverse_complement($mbl->get_region($est_orf->{contig}, $min, $prime3_distance)) . "\n";
				if($prime3_distance > $orfhash{$est_orf->{orfid}})
				{
					$orfhash{$est_orf->{orfid}} = $prime3_distance;
				}
			}
			
		}
	}
	
}

# Iterate through all the orfs and spit out the maximum est 3' utr
open(UTRMAX, ">", "est_utr_max.fasta");
open(UTRMAXINFO, ">", "est_utr_max.txt");
print UTRMAXINFO join("\t", "ORFID", "UTR_SIZE", "ORF_SIZE", "CONTIG", "ANNOTATION") . "\n";

while(my ($orfid, $distance) = each(%orfhash))
{
	my $orfattrib = $mbl->get_orf_attributes_hash($orfid);
	if($orfattrib->{direction} eq "+")
	{
		print UTRMAX ">" . $orfid . "\n" . $mbl->get_region($orfattrib->{contig}, $orfattrib->{stop}, $distance) . "\n";
	} else
	{
		print UTRMAX ">" . $orfid . "\n" . $mbl->reverse_complement($mbl->get_region($orfattrib->{contig}, $orfattrib->{start} - $distance, $distance)) . "\n";
	}
	my $annotation;
	my $annotationhash = $mbl->get_top_orf_hit($orfid);
	if(!$annotationhash)
	{
		$annotation = "None";
	} else
	{
		$annotation = $annotationhash->{description};
	}
	print UTRMAXINFO join("\t", $orfid, $distance, $orfattrib->{stop} - $orfattrib->{start} + 1, $orfattrib->{contig}, $annotation) . "\n"; 


}
#print "\n$singlets Singlets\n\n"

