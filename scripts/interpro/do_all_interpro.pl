#!/usr/bin/perl


use Bio::SeqIO;


$in  = Bio::SeqIO->new(-file => $ARGV[0] , '-format' => 'Fasta');


while(my $seq = $in->next_seq())
{
	open(FAS, ">", 'orf.fas');

	my ($id) = $seq->display_id =~ /^(\d+)/;
	print FAS ">" . $id . "\n";
	print FAS $seq->seq();
	close(FAS);
	system("/xraid/bioware/linux/iprscan_cluster/bin/iprscan -cli -i " . $ARGV[0] . " -iprlookup -goterms -format raw >> ". $ARGV[1]);
}

