#!/usr/bin/perl
                                                                                                                                                                                                                                                   
                                                                                                                                                                                                                                                   
use strict;
                                                                                                                                                                                                                                                   
use Bio::DB::GFF;
use Bio::Seq;                                                                                                                                                                                                                                                   
use Mbl;
                                                                                                                                                                                                                                                   
my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;
                                                                                                                                                                                                                                                   
                                                                                                                                                                                                                                                   
my $debug = 0;


# Select all domains of interest

my $upstream_size = 150;
my $downstream_size_max = 2000;
my $downstream_size_search = 2000;
my $meme_minimum = 8;

my $domain_list = $dbh->prepare("select accession_number, count(DISTINCT idname) as num_orfs from blast_results where db = 10 AND (evalue <= 1e-2 OR evalue is NULL) AND algorithm IN (4,6,7,9,10,12,13,14) group by accession_number having num_orfs > 3 order by num_orfs DESC");
my $get_orfs = $dbh->prepare("select DISTINCT idname from blast_results where accession_number = ? AND db = 10 AND (evalue <= 1e-2 OR evalue is NULL) AND algorithm IN (4,6,7,9,10,12,13,14)");

# Get the list of domains of interest
$domain_list->execute();
while(my $domain = $domain_list->fetchrow_hashref)
{
	system("mkdir " . $domain->{accession_number});

	# Get the list of orfs with this domain
	$get_orfs->execute($domain->{accession_number});

	# Make a fasta file with this list of orfs, with the upstream portion of this orf, and with the downstream portion of this orf
	open(ORF, ">", $domain->{accession_number} . "/orf.fasta");
	open(ORFUP, ">", $domain->{accession_number} . "/orf_upstream.fasta");
	open(ORFDOWN, ">", $domain->{accession_number} . "/orf_downstream.fasta");
	open(ORFSTAT, ">", $domain->{accession_number} . "/orf_stats.txt");
	print ORFSTAT join("\t", "ORFID", "ANNOTATION", "DOMAIN", "ORFSIZE", "DIRECTION", "CONTIG", "START", "STOP", "POLYASIZE") . "\n";
	my $down_search_size = 0;

	while(my $idname_row = $get_orfs->fetchrow_hashref)
	{
		my $orfid = $idname_row->{idname};

		## get nt sequence of this orf
		my $orf = $mbl->get_orf_attributes_hash($orfid);
                my $annotation = $mbl->get_newest_annotation($orf->{orfid});
		my $text_type = '';
		my $text_desc = '';
                if($annotation eq 'No annotation')
                {
                        my $blast_row = $mbl->get_top_orf_hit($orf->{orfid});
                        if($blast_row)
                        {
                                $text_type = 'blasthit ' . $blast_row->{evalue};
                                $text_desc = $blast_row->{hit_name} . $blast_row->{description};
                        } else
                        {
                                $text_type = 'Hypothetical Protein';
                        }
                } else
                {
                        $text_type = 'annotation';
                        $text_desc = $annotation;
                }
		my $annotation_line = $orf->{orfid} . "|$text_type|$text_desc";                                                                                                                                                                                                                                                       
                print ORF ">" . $annotation_line . "\n";
                # load this sequence into a sequence object
                my $this_sequence_obj = Bio::Seq->new( -id  => 'my_sequence',
                                -seq =>$orf->{sequence});

                print ORF $this_sequence_obj->seq();
                print ORF "\n";

		# Get ??bp's of the upstream utr
		my $up_start = $orf->{start};

		if($orf->{direction} eq "-")
		{
			$up_start = $orf->{stop};
		}

		my $upstream = $mbl->get_upstream_sequence($orf->{contig}, $up_start, $upstream_size, $orf->{direction});
		if(length($upstream) >= $meme_minimum)
		{
			print ORFUP ">" . $annotation_line . "\n" . $upstream . "\n";
		}

		# Get ??bp's of the downstream utr or search for the polyA signal within 
		my $down_start = $orf->{stop};

		if($orf->{direction} eq "-")
		{
			$down_start = $orf->{start};
		}

		my $downstream = $mbl->get_downstream_sequence($orf->{contig}, $down_start, $downstream_size_search, $orf->{direction});
		if($downstream)
		{
			my ($down_search_seq) = $downstream =~ /(.*?[AT]GT[AG]AA[TC])/;

			# Search for the first occurance of [AT]GT[AG]AA[TC}
			if(length($down_search_seq) > 1)
			{
				$down_search_size = length($down_search_seq);
				if(length($down_search_seq) > $meme_minimum)
				{
					print ORFDOWN ">" . $annotation_line . "\n" . $down_search_seq . "\n";
				}
			} elsif(length($downstream) >= $meme_minimum)
			{
				print ORFDOWN ">" . $annotation_line . "\n" . $downstream . "\n";
			}
		}
		print ORFSTAT join("\t", $orfid, $annotation_line, $domain->{accession_number}, ($orf->{stop} - $orf->{start} + 1),  $orf->{direction}, $orf->{contig}, $orf->{start}, $orf->{stop}, $down_search_size) . "\n";
		# run meme

		system("cd " . $domain->{accession_number} . ";meme -dna -nmotifs 3 -minw 6 -maxsize 100000000 orf_upstream.fasta > motifs_upstream.html");
		system("cd " . $domain->{accession_number} . ";meme -dna -nmotifs 3 -minw 6 -maxsize 100000000 orf_downstream.fasta > motifs_downstream.html");

	}


}

