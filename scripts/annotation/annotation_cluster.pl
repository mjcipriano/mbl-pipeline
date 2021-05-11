#!/usr/bin/perl
 
use strict;
 
use Mbl;
use Bio::Seq;
 

my $transfer_annotations = 0;
my $transfer_blast_results = 1;

my $blast_db_includes = "'protfun'";

my $old_mbl = Mbl::new(undef, 'giardia12');
my $old_dbh = $old_mbl->dbh;

my $new_mbl = Mbl::new(undef, 'giardia14');
my $new_dbh = $new_mbl->dbh;



my $old_orf_annotations = $old_dbh->prepare("select a.id, a.userid, a.orfid, o.sequence, a.update_dt, a.annotation, a.notes, a.delete_fg, a.blessed_fg, a.qualifier, a.with_from, a.aspect, a.object_type, a.evidence_code, a.private_fg from annotation a, user, orfs o where user.id = a.userid AND o.orfid = a.orfid AND  user.user_name != 'Admin'");

my $orfs_same_seq = $new_dbh->prepare("select o.orfid from orfs o where o.delete_fg = 'N' AND o.sequence = ?");

my $insert_orf_annot_new = $new_dbh->prepare("insert into annotation (userid, orfid, update_dt, annotation, notes, delete_fg, blessed_fg, qualifier, with_from, aspect, object_type, evidence_code, private_fg) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ? ,?, ?, ?, ?)");


my $insert_blast_new = $new_dbh->prepare("insert into blast_results (idname, score, hit_start, hit_end, hit_name, accession_number, description, algorithm, db, gaps, frac_identical, frac_conserved, query_string, hit_string, homology_string, hsp_rank, evalue, hsp_strand, hsp_frame, sequence_type_id, primary_id, query_start, query_end, hit_rank, id, gi) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?, ?, ?, ?, ?,?, ?, ?, ?, ?,?, ?, ?, ?, ?, ?)");

my $select_blast_old = $old_dbh->prepare("select orfs.sequence, br.idname, br.score, br.hit_start, br.hit_end, br.hit_name, br.accession_number, br.description, br.algorithm, br.db, br.gaps, br.frac_identical, br.frac_conserved, br.query_string, br.hit_string, br.homology_string, br.hsp_rank, br.evalue, br.hsp_strand, br.hsp_frame, br.sequence_type_id, br.primary_id, br.query_start, br.query_end, br.hit_rank, br.id, br.gi  from blast_results br, db, sequence_type st, orfs where orfs.orfid = br.idname AND db.id = br.db AND st.id = br.sequence_type_id AND st.type = 'orf' AND db.name IN ($blast_db_includes)");


my $select_blastfull_old = $old_dbh->prepare("select orfs.sequence, br.idname, br.report, br.sequence_type_id, br.db_id, br.algorithm_id from blast_report_full br, db, sequence_type st, orfs  where br.db_id = db.id AND st.id = br.sequence_type_id AND st.type = 'orf' AND orfs.orfid = br.idname AND db.name IN ($blast_db_includes)");

my $insert_blastfull_new = $new_dbh->prepare("insert into blast_report_full (idname, report, sequence_type_id, db_id, algorithm_id) VALUES (?, ?, ?, ?, ?)");

if($transfer_annotations)
{
	$old_orf_annotations->execute();

	while(my $annot_row = $old_orf_annotations->fetchrow_hashref)
	{

		# For each annotation, check for orfs in the new release that are not deleted and that share the same sequence

		$orfs_same_seq->execute($annot_row->{sequence});

		if($orfs_same_seq->rows > 0)
		{
			while(my $new_orfs_row = $orfs_same_seq->fetchrow_hashref)
			{
				$insert_orf_annot_new->execute($annot_row->{userid}, $new_orfs_row->{orfid}, $annot_row->{update_dt}, $annot_row->{annotation}, $annot_row->{notes}, $annot_row->{delete_fg}, $annot_row->{blessed_fg}, $annot_row->{qualifier}, $annot_row->{with_from}, $annot_row->{aspect}, $annot_row->{object_type}, $annot_row->{evidence_code}, $annot_row->{private_fg});
			}
		} else
		{
			warn("Orf " . $annot_row->{orfid} . " does not have a valid orf in the new assembly for transfering user annotations");
		}



	}
}


if($transfer_blast_results)
{
	$select_blast_old->execute();
	while( my $b = $select_blast_old->fetchrow_hashref)
	{
		$orfs_same_seq->execute($b->{sequence});
		if($orfs_same_seq->rows > 0)
		{
			 while(my $new_orfs_row = $orfs_same_seq->fetchrow_hashref)
			{
				$insert_blast_new->execute($new_orfs_row->{orfid}, $b->{score}, $b->{hit_start}, $b->{hit_end}, $b->{hit_name}, $b->{accession_number}, $b->{description}, $b->{algorithm}, $b->{db}, $b->{gaps}, $b->{frac_identical}, $b->{frac_conserved}, $b->{query_string}, $b->{hit_string}, $b->{homology_string}, $b->{hsp_rank}, $b->{evalue}, $b->{hsp_strand}, $b->{hsp_frame}, $b->{sequence_type_id}, $b->{primary_id}, $b->{query_start}, $b->{query_end}, $b->{hit_rank}, undef, $b->{gi});
			}
		} else
		{
			warn("Orf " . $b->{idname} . " does not have a valid orf in the new assembly for transfering blast annotations");
		}
	}
if(0) {
	# Now do the same for the full version of the search reports

	$select_blastfull_old->execute();
	while( my $b = $select_blastfull_old->fetchrow_hashref)
	{
		$orfs_same_seq->execute($b->{sequence});
		if($orfs_same_seq->rows > 0)
		{
			 while(my $new_orfs_row = $orfs_same_seq->fetchrow_hashref)
			{
				$insert_blastfull_new->execute($new_orfs_row->{orfid}, $b->{report}, $b->{sequence_type_id}, $b->{db_id}, $b->{algorithm_id});
			}
		} else
		{
			warn("Orf " . $b->{idname} . " does not have a valid orf in the new assembly for transfering blast full report annotations");
		}
	}
}

}


