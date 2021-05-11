#!/usr/bin/perl

use strict;
use Mbl;
use DBI;
use Bio::Seq;

my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh();

# This script will check that primary tags are greater then secondary tags, and if not, adjust it.
# It will also check upstream for a sagetag that is not assigned to another orf, or could not be assigned
# to another orf, and see if it's max expression is higher, and possibly a primary tag.

# First, grab all sage tags that have an orf assignment and have not been manualy updated or assigned by an est;

my $sth = $dbh->prepare("select distinct orfid from orftosage where orfid not in (select orfid from orftosage where assignment_type IN ('EST', 'manual') )");
#my $sth = $dbh->prepare("select distinct orfid from orftosage");


$sth->execute();

my $mult_check_h = $dbh->prepare("select o.tagid, o.tagtype, o.tagmapid, tm.start, tm.stop, tm.direction from orftosage o, tagmap tm where tm.id = o.tagmapid AND orfid = ? AND tagtype IN ('Primary Sense Tag', 'Alternate Sense Tag')");
my $check_max_tag_result_h = $dbh->prepare("select max(result) as max_result from sage_results where tagid = ?");

my $check_range = 20;
my $get_taginfo = $dbh->prepare("select tagid, contig, start, stop, direction, assignment, id from tagmap where tagid = ?");
my $get_tagmapinfo = $dbh->prepare("select tagid, contig, start, stop, direction, assignment, id from tagmap where id = ?");

my $check_unassign_close = $dbh->prepare("select tagid, direction, start, stop, contig from tagmap where tagid NOT IN (select tagid from orftosage where tagtype like '%Sense%') AND contig = ? AND start > ? order by start LIMIT 1");
my $check_unassign_close_pos = $dbh->prepare("select tagid, direction, start, stop, contig from tagmap where tagid NOT IN (select tagid from orftosage where tagtype like '%Sense%') AND contig = ? AND start > ? AND direction = '+' order by start LIMIT 1");
my $check_unassign_close_neg = $dbh->prepare("select tagid, direction, start, stop, contig from tagmap where tagid NOT IN (select tagid from orftosage where tagtype like '%Sense%') AND contig = ? AND start < ? AND direction = '-' ORDER by start DESC LIMIT 1");

my $get_orf_loc = $dbh->prepare("select orfid, start, stop, direction from orfs where orfid = ?");

my $check_orf_temp = $dbh->prepare("select tagid from sage_temp where orfid = ? and tagtype = 'Primary Sense Tag' AND tagid NOT IN (select tagid from orftosage)");

my $get_sum_tagexpr = $dbh->prepare("select sum(result) as total_result from sage_results where tagid = ?");

my $total_found = 0;
my $total_found_5 = 0;
my $orfs_no_primary = 0;
my $orfs_no_primary_assignment_possible = 0;
my $orfs_no_primary_possible_primary = 0;
my @dist_array;

while(my $orflist = $sth->fetchrow_hashref)
{
	# Check if there are multiple tags for this orf;
	$mult_check_h->execute($orflist->{orfid});
	my $orfinfo = $mbl->get_orf_attributes_hash($orflist->{orfid});
	# If there is more then one tag
	if($mult_check_h->rows > 1)
	{
		my $primary_tag_id = 0;
		my $primary_tag_max = 0;
		my $primary_tag_sum = 0;
		my $other_tags_max_id = 0;
		my $other_tags_max = 0;
		my $other_tags_sum = 0;
		my $other_tags_sum_id = 0;
		while(my $tagrow = $mult_check_h->fetchrow_hashref)
		{
			if($tagrow->{tagtype} eq 'Primary Sense Tag')
			{
				$primary_tag_max = get_max_result($tagrow->{tagid});
				$primary_tag_id = $tagrow->{tagid};
				$primary_tag_sum =  get_sum_result($tagrow->{tagid});
			} else
			{
				my $tagcount = get_max_result($tagrow->{tagid});
				my $sumtagres = get_sum_result($tagrow->{tagid});
				if($tagcount > $other_tags_max)
				{
					$other_tags_max = $tagcount;
					$other_tags_max_id = $tagrow->{tagid};
				}
				if($sumtagres > $other_tags_sum)
				{
					$other_tags_sum_id = $tagrow->{tagid};
					$other_tags_sum = $sumtagres;
				}
				
				
			}
		}
		if( ($other_tags_max > $primary_tag_max) && ($primary_tag_max != 0) && ($other_tags_sum > $primary_tag_sum) && ($other_tags_sum_id == $other_tags_max_id) )
		{
			print "orf:" . $orflist->{orfid} . " [primary_sagetag:$primary_tag_id is MAX:$primary_tag_max SUM:$primary_tag_sum]  [alternate_sagetag:$other_tags_max_id is MAX:$other_tags_max] [alternate_sagetag:$other_tags_sum_id is SUM:$other_tags_sum] \n";
			$total_found++;
			my $distance = $other_tags_max - $primary_tag_max;
			$dist_array[$distance]++;
			if($other_tags_max > ($primary_tag_max+5))
			{
				$total_found_5++;
			}
		} elsif($primary_tag_max == 0)
		{
			# We don't have a primary assigned for this orf - 2 reasons, there is no primary signal, or there is a primary tag that maps to two primary orfs
			# If there is no primary signal, search out more beyond the end of the orf
			$orfs_no_primary++;
			$check_orf_temp->execute($orflist->{orfid});
			if($check_orf_temp->rows > 0)
			{
				$orfs_no_primary_possible_primary++; 
			} else
			{
				# Do I have a secondary that could be a primary?
				if( $other_tags_sum_id == $other_tags_max_id )
				{
					print "orf:" . $orflist->{orfid} . " [primary_sagetag:none is MAX:0 SUM:0]  [alternate_sagetag:$other_tags_max_id is MAX:$other_tags_max] [alternate_sagetag:$other_tags_sum_id is SUM:$other_tags_sum] \n";
					$orfs_no_primary_assignment_possible++;
				}
			}
		}
	} else
	{
		# there are not multiple tags, so check if there is a better primary close by
		my $tagrow = $mult_check_h->fetchrow_hashref;
		
		if($tagrow->{tagtype} eq 'Alternate Sense Tag')
		{
			$orfs_no_primary++;
			if($check_orf_temp->rows > 0)
			{
				$orfs_no_primary_possible_primary++; 
			}
			# Get the next tag that is downstream of this tag
			my $tagmax = get_max_result($tagrow->{tagid});
			my $next_tag = get_next_tag($orfinfo->{orfid}, $tagrow->{tagmapid});
			my $nextmax = get_max_result($next_tag);
			$get_tagmapinfo->execute($next_tag);
			my $next_taginfo = $get_tagmapinfo->fetchrow_hashref;
			my $distance = 0;
			if($orfinfo->{direction} eq "+")
			{
				$distance = $next_taginfo->{start} - $orfinfo->{stop};
			} else
			{
				$distance = $orfinfo->{start} - $next_taginfo->{stop};
			}
			if($tagmax < $nextmax)
			{
		#		print "New tag possibly found for Primary Sense Tag for orf " . $orfinfo->{orfid} . "(" . $tagrow->{tagid} . ") TAG $next_tag with max of $nextmax vs Secondary max of $tagmax that is $distance bp's away\n";
			}
			
			
		}
	}
	
}

print "\n";
print "Total orfs found with possible wrong primary is $total_found\n";
print "Total orfs found with no primary and existing secondary is $orfs_no_primary\n";
print "Total orfs found with no primary and existing secondary with possible assignment is $orfs_no_primary_assignment_possible\n";
print "Total orfs found with no primary and existing secondary, but possible primary is $orfs_no_primary_possible_primary\n\n";


print "Distribution of range between Higher Alternate sense vs Primary Sense Tags\n\n";
my $count = 0;
foreach my $val (@dist_array)
{
	print "$count\t$val\n";
	$count++;
}

sub get_max_result
{
	my $tagid = shift;
	$check_max_tag_result_h->execute($tagid);
	return $check_max_tag_result_h->fetchrow_hashref->{max_result};

}
sub get_sum_result
{
	my $tagid = shift;
	$get_sum_tagexpr->execute($tagid);
	return $get_sum_tagexpr->fetchrow_hashref->{total_result};
}
sub get_next_tag
{
	my $orfid = shift;
	my $tagmapid = shift;

	# First get the location of the tag
	my $taginfo;
	if($tagmapid)
	{
		$get_tagmapinfo->execute($tagmapid);
		$taginfo = $get_tagmapinfo->fetchrow_hashref;
	}
	#get the direction of the orf
	my $orfinfo = $mbl->get_orf_attributes_hash($orfid);
	if($orfinfo->{direction} eq '+')
	{
		my $end = 0;
		if(!$tagmapid)
		{
			$end = $orfinfo->{stop};
		} else
		{
			my $end = $taginfo->{stop};
		}
		$check_unassign_close_pos->execute($orfinfo->{contig}, $end);
		if($check_unassign_close_pos->rows > 0)
		{
			my $next_tag = $check_unassign_close_pos->fetchrow_hashref->{tagid};
			return $next_tag;
		}
	} else
	{
		my $end = 0;
		if(!$tagmapid)
		{
			$end = $orfinfo->{start};
		} else
		{
			my $end = $taginfo->{start};
		}
		$check_unassign_close_neg->execute($orfinfo->{contig}, $end);
		if($check_unassign_close_neg->rows > 0)
		{
			my $next_tag = $check_unassign_close_neg->fetchrow_hashref->{tagid};
			return $next_tag;
		}
	}

}
