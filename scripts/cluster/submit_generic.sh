#!/bin/csh
#$ -j y
#$ -o /xraid/bioware/gmod/data/cblast.log
#$ -N cblast
#$ -cwd
 
setenv BLASTDB /
setenv MBLPIPE_DBFILE /xraid/bioware/gmod/mbl-pipeline/conf/db.conf
cd /xraid/habitat/mcipriano/cblast_all/;
hostname;
/xraid/bioware/gmod/mbl-pipeline/scripts/cluster/generic_search.pl $1

