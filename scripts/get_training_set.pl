#!/usr/bin/perl

use File::Temp qw/ tempfile tempdir /;
use Bio::Seq;
use Bio::SeqIO;
use Getopt::Long;

use strict;

my $organism = undef;
my $min = 1000;
my $max = 25000;
my $file = undef;
my $outfile = undef;
my $max_seq = 1000;

my $options = 	GetOptions( 	"organism=s"=>\$organism,
				"min=i"=>\$min,
				"max=i"=>\$max,
				"file=s"=>\$file,
				"output=s"=>\$outfile,
				"max_seq=i"=>\$max_seq
		);

if(!defined($outfile) || ( !defined($file) && !defined($organism) ) )
{
print "

--organism	The name of the organism database.
or
--file		The name of the file with the assembly sequence in fasta format.
--min		The minimum sequence size to accept.
--max		The maximum sequence size to accept.
--output	The name of the output file.
--max_seq	The number of sequences to find and place in the output file.

Example: get_training_set --file=testorganism --min=500 --max=20000 --max_seq=1000 --output=training.fasta

";

exit 0;
}

my $mbl;
my $dbh;

if($organism)
{
	use Mbl;
	$mbl = Mbl::new(undef, $organism);
	$dbh = $mbl->dbh;
} elsif($file)
{
}



my $assem_fh;
my $assem_fn;

if($organism && $dbh)
{
	($assem_fh, $assem_fn) = tempfile();
	my $tempassembly = Bio::SeqIO->new(-file=>">$assem_fn", -format=>'fasta');

	my $sth = $dbh->prepare("select contig_number, bases from contigs");
	$sth->execute();
	while(my $row = $sth->fetchrow_hashref)
	{
		my $seq = Bio::Seq->new(-display_id=>$row->{contig_number}, -seq=>$row->{bases});
		if($seq)
		{
			$tempassembly->write_seq($seq);
		}
	}
} elsif($file)
{
	$assem_fn = $file;	
}
my $bin = "/xraid/bioware/linux/EMBOSS-2.9.0/install/bin/getorf -sequence $assem_fn -minsize $min -maxsize $max -find 3 -outseq $outfile";
warn("get_training_set.pl running: $bin\n");
system($bin);


