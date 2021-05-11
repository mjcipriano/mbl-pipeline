
=head2 taxon_name

 Title   : taxon_name
 Usage   : print "This genome is called  " . $genome->name('full');
 Function: Gets the name of the taxon of the genome.
 Returns : A string.
 Args    : Either any point on the taxon tree (family, order, genus, species, etc), or 'full' for the complete name.

=cut

sub taxon_name
{
	my $self = shift;
	my $taxon_id = shift;
	my $type = shift;

	$type = lc($type);

	# There are many types of names, default will be the genus species, though others can be called
	# TODO: put other types of name calls

	# if no arguments, then just return the name of the highest level we know of

	if(!defined($type))
	{
		$type = 'species';
	}
	if($type eq 'species')
	{
	} elsif($type eq 'full')
	{
		my $full_name = '';
		# Follow the tree all the way back and return the name
		my @taxids = ();
		unshift(@taxids, $self->_get_name_from_taxon_id($self->seqdb_taxon_id()));
		my $parent_id = $self->_get_parent_taxon_id($self->seqdb_taxon_id);
		while(defined($parent_id) && $parent_id != 1)
		{
			unshift(@taxids, $self->_get_name_from_taxon_id($parent_id));
			$parent_id = $self->_get_parent_taxon_id($parent_id);
		}
		# Now go through it and print out the names
		$full_name = join(", ", @taxids);
		return $full_name;
	} else
	{
		$taxid = $self->seqdb_taxon_id();
	}

	# Make sure we have a seqdb_taxon_id
	if(defined($taxid))
	{
		return $self->_get_name_from_taxon_id($taxid);

	} else
	{
		return undef;
	}

	

}

=head2 _get_name_from_taxon_id

 Title   : _get_name_from_taxon_id
 Usage   : my $taxid_name = $genome->_get_name_from_taxon_id($genome->ncbi_species_taxon_id);
 Function: Gets the scientific name for any NCBI taxon id.
 Returns : A string.
 Args    : A integer.

=cut

sub _get_name_from_taxon_id
{
	my $self = shift;
        my $taxid = shift;

	my $seqdb_dbh = $self->connection()->get_seqdb_dbh();
        my $sth = $seqdb_dbh->prepare("select name from taxon_name where taxon_id = ? AND name_class = 'scientific name'");

        $sth->execute($taxid);

        if($sth->rows > 0)
        {
		my $row = $sth->fetchrow_hashref;
		$sth->finish();
                return $row->{name};
        } else
        {
                return undef;
        }

}

=head2 _get_parent_taxon_id

 Title   : _get_parent_taxon_id
 Usage   : my $parent = $genome->_get_parent_taxon_id($genome->ncbi_taxon_id);
 Function: Gets the parent taxon for a particular taxon.
 Returns : A integer.
 Args    : A integer.

=cut

sub _get_parent_taxon_id
{
	my $self = shift;
        my $taxid = shift;

	my $seqdb_dbh = $self->connection()->get_seqdb_dbh();
        my $sth = $seqdb_dbh->prepare("select parent_taxon_id from taxon where taxon_id = ?");


        $sth->execute($taxid);


        if($sth->rows > 0)
        {
		my $row = $sth->fetchrow_hashref;
		$sth->finish();
                return $row->{parent_taxon_id};
        } else
        {
                return undef;
        }


}

=head2 _get_node_rank

 Title   : _get_node_rank
 Usage   : if($genome->_get_node_rank(5443) eq 'order') { print "This is an order"; }
 Function: Gets the rank of a particular taxon id.
 Returns : A string.
 Args    : A integer.

=cut

sub _get_node_rank
{
	my $self = shift;
        my $taxid = shift;

	my $seqdb_dbh = $self->connection()->get_seqdb_dbh();
        my $sth = $seqdb_dbh->prepare("select node_rank from taxon where ncbi_taxon_id = ?");
        $sth->execute($taxid);
        if($sth->rows > 0)
        {
		my $row = $sth->fetchrow_hashref;
		$sth->finish();
                return $row->{node_rank};
        } else
        {
                return undef;
        }

}

=head2 _get_parent_rank_taxid

 Title   : _get_parent_rank_taxid
 Usage   : my $order_id = $genome->_get_parent_rank_taxid('order', $genome->ncbi_species_id);
 Function: Will search up the taxonomy tree for a specific rank, and then return that taxon id.
 Returns : A integer.
 Args    : (string, integer) which is ("the rank", "the taxon id").

=cut

sub _get_parent_rank_taxid
{
	my $self = shift;
	my $rank_name = shift;
	my $taxid = shift;

	if(!defined($taxid))
	{
		return $self->seqdb_taxon_id();
	}
        # This is for hitting the bottom
        if(!defined($taxid) || $taxid == 1)
        {
                return undef;
        }
        # First check if I am the desired rank
        if(lc($self->_get_node_rank($taxid)) eq lc($rank_name))
        {
                return $taxid;
        }

        # Ok, I'm not the rank I want, so now just keep calling my parent until either it is undef, or my rank
        return  $self->_get_parent_rank_taxid($rank_name, $self->_get_parent_taxon_id($taxid) );

}

1;
