#~/usr/bin/perl

use File::Temp qw/ tempfile tempdir /;
use Bio::Seq;
use Bio::SeqIO;
use Getopt::Long;
use Bio::Tools::Run::StandAloneBlast; 
use strict;
 
my $organism = undef;
my $match_file = undef;
my $out_file = undef;

my $options =   GetOptions(     "organism=s"=>\$organism,
				"match_file=s"=>\$match_file,
				"output=s"=>\$out_file
		);

my @params = 
my $factory = Bio::Tools::Run::StandAloneBlast->new( 	-program => 'blastn',
							-database=>$organism,
						);

open(GFF, ">$out_file");

my $match_seqs = Bio::SeqIO->new(-file=>$match_file, -format=>
while(my $seq = $match_seqs->next_seq)
{
	# Blast this sequence to the organism database
	my $report = $factory->blastall($seq);

	while(my $result = $report->next_result)
	{
		while(my $hit = $result->next_hit)
		{
			while(my $hsp = $hit->next_hsp)
			{
				
			}
		}
	}
}


