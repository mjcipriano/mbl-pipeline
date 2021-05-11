package Mbl;

use 5.008;
use strict;
use warnings;
use DBI;
use Template;
use Bio::Seq;
use Bio::AlignIO;
use IO::String;

use CGI qw(:all);


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mbl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

sub new 
{
	my $self = {};
	my $path_info = shift;
	my $database = shift;
	my $db_info = shift;

	if(!$database)
	{
		$database = $path_info;
		$database =~ s!^/!!;
	}

	if($ENV{MBLPIPE_DBFILE})
	{
		my $option_hash;
		$option_hash = process_options_file($ENV{MBLPIPE_DBFILE});
		
		$self->{DRIVER} = $option_hash->{'driver'};
		$self->{HOSTNAME} = $option_hash->{hostname};
		$self->{PORT} = $option_hash->{port};
		$self->{USER} = $option_hash->{user};
		$self->{PASSWORD} = $option_hash->{password};
	} else
	{
		$self->{DRIVER} = "mysql";
		$self->{HOSTNAME} = "jbpcdb";
		$self->{PORT} = "3306";
		$self->{USER} = "gid";
		$self->{PASSWORD} = "gidgid123";
	}

	$self->{DATABASE} = $database;
	$self->{ORGANISM} = $database;
	$self->{SHARED_DATABASE} = 'gmoddb';
	$self->{GO_DATABASE} = "go";
	$self->{WEB_SERVER} = "gmod.mbl.edu";
	$self->{WEB_HOME} = '/perl/';
	$self->{GBROWSE_CGI_DIR} = '/gb/';
	$self->{SITE_CGI} = $self->{WEB_HOME} . 'site';
	$self->{ORGANISM_HOME} = $self->{SITE_CGI} . '/' . $self->{ORGANISM};
	$self->{GBROWSE_DB_NAME} = $self->{DATABASE} . "screads";
	$self->{GBROWSE_CGI} = $self->{GBROWSE_CGI_DIR} . 'gbrowse';
	$self->{GBROWSE_ORGANISM_CGI} = $self->{GBROWSE_CGI} . '/' . $self->{GBROWSE_DB_NAME};
	$self->{GBROWSE_IMG} = $self->{GBROWSE_CGI_DIR} . 'gbrowse_img';
	$self->{GBROWSE_ORGANISM_IMG} = $self->{GBROWSE_IMG} . '/' . $self->{GBROWSE_DB_NAME};
	$self->{MBLPIPE_DIR} = '/xraid/bioware/gmod/mbl-pipeline';
	$self->{MBLDATA_DIR} = '/xraid/bioware/gmod/data';
	$self->{GMODWEB_DIR} = '/xraid/bioware/gmod/mblweb-gmod/';
	$self->{GMODWEB_HTML_TMP_SYS_DIR} = $self->{GMODWEB_DIR} . 'html/temp';
	$self->{GMODWEB_HTML_TMP_WEB_DIR} = "/temp";
	$self->{TEMPLATE_DIR} = $self->{GMODWEB_DIR} . 'templates/odb';
	$self->{TEMPLATE_DATA} = {};
	$self->{TEMPLATE} = {};
	$self->{TEMPLATE_COMPILE_DIR} = $self->{GMODWEB_DIR} . 'templates/compile';
	$self->{SESSION_TMP_DIR} = $self->{GMODWEB_DIR} . "sessions/sessions";
	$self->{SESSION_LOCK_DIR} = $self->{GMODWEB_DIR} . "sessions/lock";

	bless($self);

	$self->{QUERIES} = $self->set_queries();

	return $self;

}

sub process_options_file
{
	my $file_name = shift;
	
	my $config_hash;
	open(CONFIG, $file_name) or die ("Can not open Configuration file: $file_name\n");
	
	while(<CONFIG>)
	{
		my $line = $_;
		chomp($line);
		# First check if this is a comment line

		if($line =~ m/^\s*#/)
		{
			next;
		}

		# Now check to make sure this is a correct configuration line (it must have an equal sign and something before and after the equal sign

		if(!($line =~ /\w+\s*\=\s*[\w+\/]/))
		{
			next;
		}

		# Now process the line
		my ($variable, $value) = split("=", $line);
		# Check for a comment after the equals sign and if it's there get rid of anything after the comment
		if($value =~ /\#/)
		{
			$value =~ s/\#.*$//;
		}

		# remove whitespace from beginning and end of variables
		$variable =~ s/^\s+//;
		$variable =~ s/\s+$//;
		$value =~ s/^\s+//;
		$value =~ s/\s+$//;

		$config_hash->{$variable} = $value;
		
	}
	return $config_hash;
	close(CONFIG);
}
sub dbh
{
	my $self = shift;
	if(@_)
	{
		$self->{DBH} = shift;
	} else
	{
		my $dsn = 	"DBI:" . $self->{DRIVER} . 
				":database=" . $self->{DATABASE} . 
				";host=" . $self->{HOSTNAME} . 
				";port=" . $self->{PORT} ;
		my $dbh = DBI->connect($dsn, $self->{USER}, $self->{PASSWORD}) or return 0;
		$dbh->{mysql_auto_reconnect} = 1;
		$self->{DBH} = $dbh;
	}

	return $self->{DBH};
}

sub get_dbh
{
	my $self = shift;
	return $self->{DBH};
}
sub go_dbh
{
	my $self = shift;
	if(@_)
	{
		$self->{GO_DBH} = shift;
	} else
	{
                my $dsn =       "DBI:" . $self->{DRIVER} .
                                ":database=" . $self->{GO_DATABASE} .
                                ";host=" . $self->{HOSTNAME} .
                                ";port=" . $self->{PORT} ;
                my $dbh = DBI->connect($dsn, $self->{USER}, $self->{PASSWORD}) or die "Can not connect to database";
                $self->{GO_DBH} = $dbh;
        }
                                                                                                                             
        return $self->{GO_DBH};

}

sub shared_dbh
{
	my $self = shift;
	if(@_)
	{
		$self->{SHARED_DBH} = shift;
	} else
	{
                my $dsn =       "DBI:" . $self->{DRIVER} .
                                ":database=" . $self->{SHARED_DATABASE} .
                                ";host=" . $self->{HOSTNAME} .
                                ";port=" . $self->{PORT} ;
                my $dbh = DBI->connect($dsn, $self->{USER}, $self->{PASSWORD}) or die "Can not connect to database";
                $self->{SHARED_DBH} = $dbh;
        }
                                                                                                                             
        return $self->{SHARED_DBH};

}


sub gbrowse_dbh
{
	my $self = shift;
	if($_)
	{
		$self->{GBROWSE_DBH} = shift;
	} else
	{
		my $dsn = 	"DBI:" . $self->{DRIVER} . 
				":database=" . $self->{GBROWSE_DB_NAME}; 
				";host=" . $self->{HOSTNAME} . 
				";port=" . $self->{PORT} ;
		my $dbh = DBI->connect($dsn, $self->{USER}, $self->{PASSWORD}) or die "Can not connect to gbrowse database";
		$dbh->{mysql_auto_reconnect} = 1;
		$self->{GBROWSE_DBH} = $dbh;
	}

	return $self->{GBROWSE_DBH};

}

sub organism
{
	my $self = shift;
	if(@_)
	{
		$self->{ORGANISM} = shift;
	}

	return $self->{ORGANISM};
}

sub web_home
{
	my $self = shift;
	if(@_)
	{
		$self->{WEB_HOME} = shift;
	}

	return $self->{WEB_HOME};
}

sub site_cgi
{
        my $self = shift;
        if(@_)
        {
                $self->{SITE_CGI} = shift;
        }
                                                                                                                             
        return $self->{SITE_CGI};

}

sub organism_home
{
        my $self = shift;
        if(@_)
        {
                $self->{ORGANISM_HOME} = shift;
        }

        return $self->{ORGANISM_HOME};

}

sub gbrowse_db_name
{
        my $self = shift;
        if(@_)
        {
                $self->{GBROWSE_DB_NAME} = shift;
        }
        return $self->{GBROWSE_DB_NAME};
}

sub gbrowse_cgi
{
        my $self = shift;
        if(@_)
        {
                $self->{GBROWSE_CGI} = shift;
        }
        return $self->{GBROWSE_CGI};
}

sub gbrowse_organism_cgi
{
        my $self = shift;
        if(@_)
        {
                $self->{GBROWSE_ORGANISM_CGI} = shift;
        }
        return $self->{GBROWSE_ORGANISM_CGI};
}

sub organism_web_server
{
        my $self = shift;
        if(@_)
        {
                $self->{WEB_SERVER} = shift;
        }
        return $self->{WEB_SERVER};
}

sub gbrowse_img
{
        my $self = shift;
        if(@_)
        {
                $self->{GBROWSE_IMG} = shift;
        }
        return $self->{GBROWSE_IMG};
}

sub gbrowse_organism_img
{
        my $self = shift;
        if(@_)
        {
                $self->{GBROWSE_ORGANISM_IMG} = shift;
        }
        return $self->{GBROWSE_ORGANISM_IMG};
}

sub gmodweb_dir
{
        my $self = shift;
        if(@_)
        {
                $self->{GMODWEB_DIR} = shift;
        }
        return $self->{GMODWEB_DIR};
}

sub mblpipe_dir
{
	my $self = shift;
	if(@_)
	{
		$self->{MBLPIPE_DIR} = shift;
	}
	return $self->{MBLPIPE_DIR};
}

sub mbldata_dir
{
	my $self = shift;
	if(@_)
	{
		$self->{MBLDATA_DIR} = shift;
	}
	return $self->{MBLDATA_DIR};
}
sub gmodweb_html_tmp_sys_dir
{
	my $self = shift;
	if(@_)
	{
		$self->{GMODWEB_HTML_TMP_SYS_DIR} = shift;
	}
	return $self->{GMODWEB_HTML_TMP_SYS_DIR};
}
sub gmodweb_html_tmp_web_dir
{
	my $self = shift;
	if(@_)
	{
		$self->{GMODWEB_HTML_TMP_WEB_DIR} = shift;
	}
	return $self->{GMODWEB_HTML_TMP_WEB_DIR};
}

sub template_dir
{
        my $self = shift;
        if(@_)
        {
                $self->{TEMPLATE_DIR} = shift;
        }
        return $self->{TEMPLATE_DIR};
}

sub template_compile_dir
{
        my $self = shift;
        if(@_)
        {
                $self->{TEMPLATE_COMPILE_DIR} = shift;
        }
        return $self->{TEMPLATE_COMPILE_DIR};
}

sub template
{
	my $self = shift;

	if(@_)
	{
		$self->{TEMPLATE} = shift;
	} else
	{
		$self->{TEMPLATE} =  Template->new({
			INCLUDE_PATH => $self->template_dir() . "/src:" . $self->template_dir() . "/lib",
			EVAL_PERL =>1,
			COMPILE_DIR=>$self->template_compile_dir(),
			TRIM =>1,
			PRE_CHOMP=>1,
			POST_CHOMP=>1
		});
	}
	return $self->{TEMPLATE};
}

sub template_data
{
	my $self = shift;
        return $self->{TEMPLATE_DATA};
}

sub get_template_file_name
{
	my $self = shift;
        my $page_name = shift;

        my $gfh = $self->query('get_template_file_name');

        $gfh->execute($page_name);
	
        my $row = $gfh->fetchrow_hashref;
	if($row)
	{		
		return $row->{template_file};
        } else
        {
                return 'default.tt';
        }

}
sub get_value
{
	my $self = shift;
	my $template = shift;
	my $variable = shift;

	my $sth = $self=>query('get_value');

	$sth->execute($template, $variable);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{value};
	} else
	{
		return undef;
	}


}

sub check_page_exists
{
	my $self = shift;
	my $page_name = shift;
	my $user_id = shift;

	my $sth = $self->query('page_data');

	$sth->execute($page_name);

	if($sth->rows() > 0)
	{
		return 1;
	}

	return 0;
}

sub set_template_data_var
{
	my $self = shift;
        my $page_name = shift;
        my $sth = $self->query('get_template_variable_value');
        my $data;

        # First populate the default values
        $sth->execute("default");
        while(my $row_val = $sth->fetchrow_hashref)
        {
		if($row_val->{variable})
		{
                	$data->{$row_val->{variable}} = $row_val->{value};
		}
        }
        # Now populate the page values, overwriting the defaults if similar
        $sth->execute($page_name);
        while(my $row_val = $sth->fetchrow_hashref)
        {
		if($row_val->{variable})
		{
                	$data->{$row_val->{variable}} = $row_val->{value};
		}
        }

        $self->{TEMPLATE_DATA} = $data;
	return $self->{TEMPLATE_DATA};
}


sub session_tmp_dir
{
        my $self = shift;
        if(@_)
        {
                $self->{SESSION_TMP_DIR} = shift;
        }
        return $self->{SESSION_TMP_DIR};
}

sub session_lock_dir
{
        my $self = shift;
        if(@_)
        {
                $self->{SESSION_LOCK_DIR} = shift;
        }
        return $self->{SESSION_LOCK_DIR};
}

sub get_session
{
	my $self = shift;
	my $session_id = shift;
	my $session_ref = shift;

        tie %{$session_ref}, "Apache::Session::File", $session_id, {
                Directory => $self->session_tmp_dir()
        };
	$self->{SESSION_HASH} = $session_ref;
	$self->{SESSION_ID} = $session_id;
        return $self->{SESSION_HASH};
}

sub untie_session
{
	my $self = shift;
	untie(%{$self->{SESSION_HASH}});
	return 1;
}


sub orf_link
{
	my $self = shift;
	my $orfid = shift;
	return '<a href="' . $self->organism_home() . "?page=showorf&orf=$orfid" . '">' . $orfid . '</a>';
}

sub add_orf_link
{
	my $self = shift;
	my $contig = shift;
	my $start = shift;
	my $stop = shift;
	my $dir = shift;
	my $raw = shift;

	if($contig =~ /contig_/)
	{
	} else
	{
		$contig = 'contig_' . $contig;
	}
	if($raw)
	{
		return  $self->organism_home() . "?page=edit_orf&orf=new&type=new_orf&new_contig=$contig&new_start=$start&new_stop=$stop&new_direction=$dir";
	} else
	{	
		return '<a href="' .  $self->organism_home() . "?page=edit_orf&orf=new&type=new_orf&new_contig=$contig&new_start=$start&new_stop=$stop&new_direction=$dir\">Add</a>";
	}
}
sub read_link
{
	my $self = shift;
	my $read_name = shift;
	return '<a href="' . $self->organism_home() . '?page=showread&read=' . $read_name . '">' . $read_name . '</a>';
}

sub read_fasta_link
{
	my $self = shift;
	my $read_name = shift;
	my $display = shift;
	if(!$display)
	{
		$display = $read_name;
	}
	return '<a href="' . $self->organism_home() . '?page=showreadfasta&read=' . $read_name . '">' . $display . '</a>';
}

sub contig_fasta_link
{
        my $self = shift;
        my $contig_name = shift;
        my $display = shift;
        if(!$display)
        {
                $display = $contig_name;
        }
        return '<a href="' . $self->organism_home() . '?page=showcontigfasta&contig=' . $contig_name . '">' . $display . '</a>';
}

sub contig_alignment_link
{
        my $self = shift;
        my $contig_name = shift;
        my $display = shift;
        if(!$display)
        {
                $display = $contig_name;
        }
        return '<a href="' . $self->organism_home() . '?page=contigma&contig=' . $contig_name . '">' . $display . '</a>';
}

sub orf_multiple_alignment_link
{
	my $self = shift;
	my $orfid = shift;
	return '<a href="' . $self->organism_home() . "?page=orfma&orf=$orfid&select_seqs=Y\">Create Multiple Alignment</a>";
}

sub orf_multiple_alignment_button
{
	my $self = shift;
	my $orfid = shift;
	return '<form action="' . $self->organism_home() . '"><input type=hidden name="page" value="orfma">' .
		'<input type=hidden name="orf" value="' . $orfid . '"><input type=hidden name="select_seqs" value="Y">' .
		'<input type="submit" name="Submit" value="Create Multiple Sequence Alignment"></form>';
}

sub gbrowse_orf_link
{
	my $self = shift;
	my $orfid = shift;
	if($orfid eq '')
	{
		return '';
	}
	return '<a href="' . $self->gbrowse_organism_cgi() . '?name=Orf:' . $orfid . '">' . $orfid . '</a>';
}

sub gbrowse_contig_link
{
	my $self = shift;
	my $contig = shift;

	my ($contig_id) = $contig =~ /(\d+)/;

	return '<a href="' . $self->gbrowse_organism_cgi() . '?name=contig_' . $contig_id . '">' . $contig_id . '</a>';
}

sub contig_link
{
	my $self = shift;
        my $contig = shift;
                                                                                                                           
        my ($contig_id) = $contig =~ /(\d+)/;
                                                                                                                           
        return '<a href="' . $self->organism_home() . '?page=showcontig&contig=' . $contig_id . '">' . $contig_id . '</a>';
}

sub gbrowse_supercontig_link
{
        my $self = shift;
        my $supercontig = shift;
        my ($supercontig_id) = $supercontig =~ /(\d+)/;
                                                                                                                           
        return '<a href="' . $self->gbrowse_organism_cgi() . '?name=supercontig_' . $supercontig_id . '">' . $supercontig_id . '</a>';
}

sub contig_linking_reads_link
{
	my $self = shift;
	my $contig_one = shift;
	my $contig_two = shift;
	my $display = shift;
	return '<a href="' . $self->organism_home() . "?page=showcontiglinking&contig_one=$contig_one&contig_two=$contig_two\">$display</a>";

}
sub gbrowse_blast_button
{
	my $self = shift;
	my $sequence = shift;
	return '<form  method=POST action="' . $self->gbrowse_organism_cgi() . '"><input type=hidden name="plugin" value="SequenceFinder"><input type=hidden name="plugin_action" value="Find"><input type=hidden name="SequenceFinder.searchsequence" value="' . $sequence . '"><input type=submit name="Gbrowse" value="Gbrowse"></form>';

}

sub gblast_form
{
	my $self = shift;
	my $sequence = shift;
	my $program = shift;
	my $database = shift;
	my $display_name = shift;
	my $header = shift;

	#warn	'<input type=hidden name="seq" value=">' . $header . "\n". $sequence . '">';
	#warn	'<input type=hidden name="page" value="gblast">';
	#warn	'<input type=hidden name="program" value="' . $program . '">';
	#warn	'<input type=hidden name="database" value="' . $database . '">';
	#warn	'<input type=submit name="Blast" value="' . $display_name . '">';
	#warn	'</form>';
	#warn    '<form  method=POST action="' . $self->organism_home() . '">';

	return '<form  method=POST action="' . $self->organism_home() . '">
		<input type=hidden name="seq" value=">' . $header . "\n". $sequence . '">
		<input type=hidden name="page" value="gblast">
		<input type=hidden name="program" value="' . $program . '">
		<input type=hidden name="database" value="' . $database . '">
		<input type=submit name="Blast" value="' . $display_name . '">
		</form>';
}

sub ncbi_blast
{
	my $self = shift;
	my $sequence = shift;
	my $program = shift;
	my $database = shift;
	my $display_name = shift;

	return '<form  method=POST action="' . 'http://www.ncbi.nlm.nih.gov/blast/Blast.cgi?CMD=Web&LAYOUT=TwoWindows&AUTO_FORMAT=Semiauto&PAGE=Proteins&NCBI_GI=yes&HITLIST_SIZE=100&COMPOSITION_BASED_STATISTICS=yes&SHOW_OVERVIEW=yes&AUTO_FORMAT=yes&CDD_SEARCH=yes&FILTER=L&SHOW_LINKOUT=yes">' .
	' <input type=hidden name="QUERY" value="' . $sequence . '">
	<input type=submit name="Blast" value="' . $display_name . '">
	</form';
}

sub cgi_blast_button
{
	my $self = shift;
	my $sequence = shift;
	my $db = shift;
	my $program = shift;
	my $new_program = $program;

	if(!$db)
	{
		$db = $self->organism();
		$program = 'blastn';
	} elsif($db eq 'organism')
	{
		$db = $self->organism();
		$program = 'blastn';
	} elsif($db eq 'orf_aa')
	{
		$db = $self->organism() . '_orfs_aa';
		$program = 'blastp';
	} elsif($db eq 'orf_nt')
	{
		$db = $self->organism() . '_orfs_nt';
		$program = 'blastn';
	} elsif($db eq 'unused_reads')
	{
		$db = $self->organism() . '_unused_reads';
		$program = 'blastn';
	}

	if(!$new_program)
	{
		# Do nothing
	} else
	{
		$program = $new_program;
	}

	return '<form ACTION="' . $self->organism_home() . '?page=gblastresults" METHOD="POST" NAME="MainBlastForm" ENCTYPE=" multipart/form-data"><input type=hidden name="DATALIB" value="' . $db . '"><input type=hidden name="SEQUENCE" value="' . $sequence . '"><input type=hidden name="PROGRAM" value="' . $program . '"><input type=hidden name="show_img" value="yes"><input type=submit name="Blast" value="Blast Report"><input type=hidden name="page" value="gblastresults"></form>';

}
sub page_link
{
	my $self = shift;
	my $page_name = shift;
	my $page_text = shift;
	if(!defined($page_text))
	{
		$page_text = ucfirst(lc($page_name));
	}
	return '<a href="' . $self->organism_home() . "?page=$page_name\">$page_text</a>";
}


sub sagetag_link
{
	my $self = shift;
	my $tagid = shift;
	my $description = shift;
	my $tags = shift;

	if(!$description)
	{
		$description = $tagid;
	}
	if(!$tags)
	{
		$tags = ' ';
	}

	return '<a href="' . $self->organism_home() . "?page=showsagetag&tag=$tagid" . "\" $tags>" . $description . '</a>';
}

sub ncbi_link
{
	my $self = shift;
	my $search_term = shift;
	return '<a href="http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=protein&cmd=Search&term=' . $search_term . '">' . $search_term . '</a>';

}

sub show_blast_full_link
{
	my $self = shift;
	my $orfid = shift;
	my $seq_type = shift;
	my $blast_db = shift;
	my $display = shift;
	my $target = shift;

	if($target)
	{
		$target = "#$target";
	} else
	{
		$target = "";
	}

	if(!$display)
	{
		$display = $blast_db;
	}
	#warn "<a href=\"?page=blastfull&idname=$orfid&type=$seq_type&db=$blast_db$target\">$display</a>";
	return "<a href=\"?page=blastfull&idname=$orfid&type=$seq_type&db=$blast_db$target\">$display</a>";

}

sub get_full_blast_report
{
	my $self = shift;
	my $idname = shift;
	my $type = shift;
	my $db = shift;

	my $sth = $self->query('get_full_blast_report');
	$sth->execute($idname, $type, $db);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{report};
	} else
	{
		return undef;
	}
 
}

sub stored_multiple_alignment_link
{
	my $self = shift;
	my $id = shift;
	my $description = shift;
	my $orfid = shift;
	my $type = shift;
	
	if(!defined($type))
	{
		$type = 'text';
	}
		
	my $retval = "<a href=\"?page=ma&id=$id&orf=$orfid";
	if($type eq 'jalview')
	{
		$retval .= '&noheader=T'
	}
	
	$retval .= "&type=$type\">$description</a>";

}

sub stored_tree_link
{
        my $self = shift;
        my $id = shift;

        return 'http://' . $self->organism_web_server . $self->organism_home . "?page=tree&id=$id";
}

sub tree_page_link
{
        my $self = shift;
        my $id = shift;
        my $description = shift;
        my $type = shift;
                                                                                                                           
        #return "<a href=\"?page=atv&id=$id\" target=_new>$description($type)</a>";
        return "<a href=\"?page=ma&id=$id&type=atv&noheader=T\" target=_new>$description($type)</a>";
}

sub modify_tree_string
{
	my $self = shift;
	my $tree = shift;

	# Find and replace gi #'s with gi#'s + descriptions + species if possible


	my %gi_hash;
	my %gn1_hash;
	my $ret_string = '';
	my $num = 1;
	while($tree =~ /gi\|\d+\:\d+\.\d+/g)
	{
		$gi_hash{$num} = $&;
		$num++;
	}
	while($tree =~ /gn1\|\w+?\|\d+\:\d+\.\d+/g)
	{
		$gn1_hash{$num} = $&;
		$num++;
	}
	while(my ($key, $val) = each(%gi_hash))
	{
		# Get the gi number out of the string
		my $new_string = $val;
		my $extended = '';
		my ($gi) = $val =~ /gi\|(\d+)/;
		my $taxid = $self->get_taxid_from_gi($gi);
		if($taxid)
		{
			$extended .= ":T=$taxid";
			my $name = $self->fix_tree_desc($self->get_taxon_name_from_taxid($taxid));
			$extended .= ":S=$name";
		}
		if($extended)
		{
			$new_string .= "[&&NHX" . $extended . ']';
			$val =~ s/\|/\\\|/g;
			$val =~ s/\./\\\./g;
			$tree =~ s/$val/$new_string/gi;
		}
	}

        while(my ($key, $val) = each(%gn1_hash))
        {
                # Get the gi number out of the string
                my $new_string = $val;
                my $extended = '';
                my ($db, $idnum) = $val =~ /gn1\|(.+)\|(\d+)/;
		my $taxid;
		if($db eq "gdb")
		{
			$taxid = 5741;
		}	
                if($taxid)
                {
                        $extended .= ":T=$taxid";
                        my $name = $self->fix_tree_desc($self->get_taxon_name_from_taxid($taxid));
                        $extended .= ":S=$name";
                }
                if($extended)
                {
                        $new_string .= "[&&NHX" . $extended . ']';
                        $val =~ s/\|/\\\|/g;
                        $val =~ s/\./\\\./g;
                        $tree =~ s/$val/$new_string/gi;
                }
        }

	return $tree;
}

sub fix_tree_desc
{
	my $self = shift;
	my $name = shift;

	$name =~ s/\ /\-/g;
	$name =~ s/\(/\|/g;
	$name =~ s/\)/\|/g;
	return $name;
}


sub orf_edit_form
{
	my $self = shift;
	my $orfid = shift;
	my $variable_name = shift;
	my $display_name = shift;

	return "<a href=\"?page=edit_orf&orf=$orfid&edit_type=$variable_name\">$display_name</a>";

}


sub set_queries
{
	my $self = shift;
	my $query;

	# Access
	$query->{'check_login_old'} = "select id, user_name, first_name, last_name from user where lower(user_name) = lower(?) AND password = old_password(?) AND active_fg = 'Y'";
	#$query->{'check_login'} = "select id, user_name, first_name, last_name from user where lower(user_name) = lower(?) AND password = old_password(?) AND active_fg = 'Y'";
	$query->{'check_login'} = "select id, user_name, first_name, last_name from user where lower(user_name) = lower(?) AND password = password(?) AND active_fg = 'Y'";
	$query->{'login_info'} = "select id, user_name, first_name, last_name, active_fg, email, institution from user where id = ?"; 
	$query->{'get_userid_from_username'} = "select id from user where user_name = ?";
	# Annotation Queries
	$query->{'list_annotationadmin'} = "select a.id, a.userid, a.orfid, a.update_dt, a.annotation, a.delete_fg, a.blessed_fg, u.user_name, u.email from annotation a, user u where u.id = a.userid AND a.orfid = ? order by update_dt DESC";
	$query->{'list_annotationuser'} = "select a.id, a.userid, a.orfid, a.update_dt, a.annotation, a.delete_fg, a.blessed_fg, a.private_fg, u.user_name, u.email from annotation a, user u where u.id = a.userid AND a.orfid = ? AND (a.userid = ? OR (a.delete_fg = 'N') ) order by a.blessed_fg DESC, a.update_dt DESC";
	$query->{'list_annotation_id'} = "select a.id, a.userid, a.orfid, a.update_dt, a.annotation, a.notes, a.delete_fg, a.blessed_fg, a.qualifier, a.with_from, a.aspect, a.object_type, a.evidence_code, a.private_fg, u.user_name, u.email from annotation a, user u where u.id = a.userid AND a.id = ?";
	$query->{'check_annotation_add_rights'} = "select id from user_rights where userid = ? AND rights IN ( 'Add Annotation', 'Annotation Admin')";
	$query->{'check_annotation_admin_rights'} = "select id from user_rights where userid = ? AND rights IN ('Annotation Admin')";

	$query->{'check_orf_existance'} = "SELECT orfid from orfs where orfid = ? AND delete_fg = 'N'";
	$query->{'check_orf_existance_all'} = "SELECT orfid from orfs where orfid = ?";
	$query->{'get_evidence_code_id'} = "select id from evidence_codes where (code = ? OR description = ?)";
	$query->{'get_newest_annotation'} = "SELECT annotation from annotation where orfid = ? and delete_fg = 'N' AND blessed_fg = 'Y' order by update_dt DESC LIMIT 1";
	$query->{'add_annotation'} = "insert into annotation (userid, orfid, annotation, notes, delete_fg, blessed_fg, qualifier, with_from, aspect, object_type, evidence_code, private_fg) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

	# Template Queries
	$query->{'get_template_file_name'} = "select template_file from templates where page_name = ?";
	$query->{'get_template_variable_value'} = "select variable, value from html where template = ?";
	$query->{'get_value'} = "select value from html where template = ? AND variable = ?";
	$query->{'page_data'} = 'select id, template_file, page_name from templates where page_name = ?';

	# Orf queries
	$query->{'get_orf_sequence'} = "select sequence, contig, start, stop, direction from orfs where orfid = ?";
	$query->{'get_orf_attrib'} = "select orfid, contig, start, stop, direction, attributes, TestCode, CodonScore, CodonPreference, TestScore, GeneScan, GeneScanScore, CodonUsage, CodonPreferenceScore, orf_name, annotation, annotation_type, source, delete_reason, delete_fg from orfs where orfid = ?";
	$query->{'get_orf_sagetags'} = "select tagid, tagtype from orftosage where orfid = ?";
	$query->{'get_orf_blast_results'} = "select br.idname, br.score, br.hit_name, br.evalue, br.hit_start, br.hit_end, br.query_start, br.query_end, br.accession_number, br.gi, br.description, br.frac_identical, br.frac_conserved, db.name from blast_results br, sequence_type st, db where st.type = 'orf'
	AND st.id = br.sequence_type_id AND db.name IN ('nr','swissprot','Pfam_ls','mitop', 'RefEuks', 'RefTax') AND br.idname = ? AND br.evalue < ?  AND (br.description not like '%ATCC %' OR br.description like '%gb|%') AND br.db = db.id ORDER BY br.db, br.evalue ";
	$query->{'get_blast_annotation'} = "select br.idname, br.score, br.hit_name, br.evalue, br.hit_start, br.hit_end, br.query_start, br.query_end, br.accession_number, br.gi, br.description, br.frac_identical, br.frac_conserved, db.name from blast_results br, sequence_type st, db,algorithms where algorithms.id = br.algorithm AND br.idname = ? AND st.type = ? AND st.id = br.sequence_type_id AND db.name = ? AND br.db = db.id AND algorithms.name = ?";

	$query->{'get_orf_feature_results'} = "select br.idname, br.hit_name, br.score, br.evalue, br.hit_start, br.hit_end, br.query_start, br.query_end, br.accession_number, br.gi, br.description, br.frac_identical, br.frac_conserved, br.primary_id, db.name as db_name, algorithms.name as algorithms_name from blast_results br, sequence_type st, db, algorithms  where st.type = 'orf'
	AND st.id = br.sequence_type_id AND algorithms.id = br.algorithm AND db.name IN ('Pfam_ls', 'interpro', 'tmhmm', 'signalp') AND br.idname = ? AND (br.evalue < ? OR br.evalue is NULL)  AND (br.description not like '%ATCC %' OR br.description like '%gb|%') AND br.db = db.id ORDER BY br.db, br.algorithm, br.query_start, br.evalue ";
	$query->{'get_orf_feature_results_reduced'} = "select br.idname, br.hit_name, br.score, br.evalue, br.hit_start, br.hit_end, br.query_start, br.query_end, br.accession_number, br.gi, br.description, br.frac_identical, br.frac_conserved, br.primary_id, db.name as db_name, algorithms.name as algorithms_name from blast_results br, sequence_type st, db, algorithms  where st.type = 'orf'
	AND st.id = br.sequence_type_id AND algorithms.id = br.algorithm AND db.name IN ('Pfam_ls', 'interpro', 'signalp') AND br.idname = ? AND (br.evalue < ? OR br.evalue is NULL)  AND (br.description not like '%ATCC %' OR br.description like '%gb|%') AND br.db = db.id AND br.description != 'seg' ORDER BY br.db, br.algorithm, br.query_start, br.evalue ";
	$query->{'check_full_blast_report'} = "select brf.idname FROM blast_report_full brf, sequence_type st, db  WHERE db.id = brf.db_id AND st.id = brf.sequence_type_id AND st.type = ? AND db.name = ? AND brf.idname = ?";
	$query->{'get_orf_top_blast_hit'} = "select hit_name, description, evalue, score, id, gi, accession_number from blast_results where sequence_type_id = 2 AND db IN (2,3) AND algorithm = 3 AND idname = ? AND evalue <= ? AND (description not like '%ATCC 50803%' OR description like '%gb|%') order by evalue limit 1";
	$query->{'delete_orf'} = "update orfs set delete_fg = 'Y', delete_reason = ?, delete_user_id = ? where orfid = ?";
	$query->{'undelete_orf'} = "update orfs set delete_fg = 'N', delete_reason = NULL, delete_user_id = NULL where orfid = ?";
	$query->{'update_orf_coordinates'} = "update orfs set contig = ?, start = ?, stop = ?, direction = ? where orfid = ?";
	$query->{'update_orf_sequence'} = 'update orfs set sequence = ? where orfid = ?';
	$query->{'insert_orf'} = "insert into orfs (orfid, contig, start, stop, direction, sequence, delete_fg, delete_reason, source) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
	$query->{'get_sequence_type_id'} = "select id from sequence_type where type = ?";
	$query->{'get_sequence_type_name'} = "select type from sequence_type where id = ?";
	$query->{'get_db_name'} = "select name from db where id = ?";
	$query->{'get_db_id'} = "select id from db where name = ?";
	$query->{'get_algorithm_name'} = "select name from algorithms where id = ?";
	$query->{'get_algorithm_id'} = "select id from algorithms where name = ?";
	$query->{'get_transmembrane_domains'} = "select count(br.idname) as num_domains from blast_results br, db, sequence_type st, algorithms al where st.type = 'orf' AND st.id = br.sequence_type_id AND (db.name='tmhmm' OR db.name = 'interpro') AND db.id = br.db AND al.id = br.algorithm AND al.name = 'tmhmm' AND br.description = 'TMhelix' AND idname = ?";
	$query->{'get_signal_peptide'} = "select distinct br.idname, br.description from blast_results br, db, sequence_type st where st.id = br.sequence_type_id AND db.id = br.db AND st.type = 'orf' AND db.name = 'signalp' AND br.idname = ?";
	

	# Assembly queries
	$query->{'get_supercontigs_size_list'} = "select distinct super_id as id, super_id, bases_in_super, contigs_in_super, modified_bases_in_super as total_length, modified_bases_in_super from links where modified_bases_in_super between ? AND  ? order by modified_bases_in_super DESC";
	$query->{'get_supercontigs_size_list_singlet'} = "select distinct super_id as id, super_id, bases_in_super, contigs_in_super, modified_bases_in_super as total_length, modified_bases_in_super from links where modified_bases_in_super between ? AND  ? AND contigs_in_super = 1 order by modified_bases_in_super DESC";
	$query->{'get_contigs_size_list'} = "select contig_number as id, contig_length as total_length, super_id from links where contig_length between
	? AND ?";
	$query->{'get_sum_ontigs_size_in_supercontig_between'} = "select sum(contig_length) as contig_sum from links where modified_bases_in_super between ? AND ? order by modified_bases_in_super DESC";
	$query->{'get_num_contigs_in_supercontig_between'} = "select count(*) as num_contigs from links where modified_bases_in_super between ? AND ?";
	$query->{'check_contig_exists'} = "select contig_number from contigs where contig_number = ?";
	$query->{'get_contig_subsequence'} = "select substring(bases, ?, ?) as seq from contigs where contig_number = ?";
	$query->{'total_contigs'} = "select count(*) as num_contigs from links";
	$query->{'all_supercontigs'} = "select distinct super_id from links";
	$query->{'total_contig_bases'} = "select sum(contig_length) as bases from links";
	$query->{'num_contigs_in_supercontig'} = "select count(*) as num_contigs from links where super_id = ?";
	$query->{'num_contig_bases_in_supercontig'} = "select sum(contig_length) as num_bases from links where super_id = ?";
	$query->{'modified_supercontig_length'} = "select distinct modified_bases_in_super from links where super_id = ?";
	$query->{'contig_info'} = "select contig_number, super_id, contig_start_super_base, contig_length, ordinal_number, modified_contig_start_base, gap_before_contig, gap_after_contig, bases_in_super, contigs_in_super, modified_bases_in_super from links where contig_number = ?";
	$query->{'contig_links'} = "SELECT distinct r_assem.read_pair_contig_number, COUNT(*) as read_count, links.super_id AS super_contig_number FROM reads_assembly r_assem, links WHERE links.contig_number = r_assem.contig_number AND r_assem.read_pair_contig_number != r_assem.contig_number AND r_assem.contig_number = ? GROUP by links.super_id, r_assem.read_pair_contig_number";

	$query->{'contig_linking_reads'} = "SELECT distinct r_assem.read_pair_contig_number, r_assem.read_name, r_assem.read_pair_name, orientation, links.super_id AS super_contig_number FROM reads_assembly r_assem, links WHERE links.contig_number = r_assem.contig_number AND r_assem.read_pair_contig_number != r_assem.contig_number AND r_assem.contig_number = ? AND r_assem.read_pair_contig_number = ?";

	$query->{'contig_reads'} = "SELECT read_name, contig_length, trim_read_in_contig_start, trim_read_in_contig_stop, first_base_of_trim, read_len_trim, read_len_untrim from reads_assembly where contig_number=?";

	$query->{'read_information'} = "select distinct
reads.read_name,
reads.center_name,
reads.plate_id,
reads.well_id,
reads.template_id,
reads.library_id,
reads.trace_end,
reads.trace_direction,
reads.status,
rassem.read_status,
rassem.read_len_untrim,
rassem.first_base_of_trim,
rassem.read_len_trim,
rassem.contig_number,
rassem.contig_length,
rassem.trim_read_in_contig_start,
rassem.trim_read_in_contig_stop,
rassem.orientation,
rassem.read_pair_name,
rassem.read_pair_status,
rassem.read_pair_contig_number,
rassem.observed_insert_size,
rassem.given_insert_size,
rassem.given_insert_std_dev,
rassem.observed_inserted_deviation
from reads
LEFT OUTER JOIN reads_assembly rassem ON reads.read_name = rassem.read_name
WHERE reads.read_name = ?";

	$query->{'read_sequence'} = "select bases from reads_bases where read_name = ?";
	$query->{'read_sequence_trim'} = "select substring(rb.bases, ra.first_base_of_trim, ra.read_len_trim) as bases from reads_bases rb, reads_assembly ra WHERE rb.read_name = ? AND ra.read_name = rb.read_name";

	$query->{'read_pair_template'} = "select read_name from reads where read_name != ? AND template_id = ?";

	$query->{'get_read_qual'} = "select read_name, quality from reads_quality where read_name = ?";
	$query->{'get_contig_qual'} = "select contig_number, quality from contig_quality where contig_number = ?";

	# SAGE queries
	$query->{'get_library_access'} = "select distinct ur.rights as library from user_rights ur, sage_library_names sn  where (ur.userid = ? OR ur.userid is NULL) AND sn.library = ur.rights AND ur.type = 'sage_library_access' order by sn.priority";
	$query->{'sage_count_map'} = "select count(*) as num_map from tagmap where tagid = ?";
	$query->{'sagetag_orf_assignment'} = "select orfid, tagtype, unique_genome_fg, unique_trans_fg, tagmapid, manual_fg from orftosage where tagid = ?";
	$query->{'sage_library_totals'} = "select library, total from sage_library_names where total is not null";
	$query->{'sage_library_total'} = "select library, total from sage_library_names where library = ?";
	$query->{'sage_library_totals_filtered'} = "select library, total_filtered as total from sage_library_names where total is not NULL";
	$query->{'sage_library_total_filtered'} = "select library, total_filtered as total from sage_library_names where library = ?";

	$query->{'sage_sequence'} = "select sequence from sage_tags where tagid = ?";
	$query->{'sage_library_detail'} = "select library, name, short_name, priority from sage_library_names where library = ?";

	$query->{'sage_top_blast_tag'} = "select  br.idname, br.accession_number, br.description, br.hit_name, br.evalue,
                                                br.frac_identical, length(st.sequence) as seq_length, length(br.hit_string) as hit_length
                                                from blast_results br, sage_tags st where br.idname = ?
                                                AND br.sequence_type_id = 4
                                                AND br.frac_identical > 0.75 AND st.tagid = br.idname
                                                AND length(st.sequence) - 2 <= length(br.hit_string)
                                                order by length(st.sequence) DESC, frac_identical DESC LIMIT 1";

	$query->{'sage_by_orfid'} = "select tagid from orftosage where orfid = ?";
	$query->{'orf_primary_tag'} = "select tagid from orftosage where orfid = ? AND tagtype = 'Primary Sense Tag'";
	$query->{'sage_orf_tagtypes'} = "select tagid from orftosage where orfid = ? AND tagtype = ?";

	# TAXON queries

	$query->{'get_taxid_gi'} = "select taxid from gmoddb.gitotaxon where gi = ?";
	$query->{'get_name_from_taxid'} = "select name from gmoddb.taxon_name where taxon_id = ? AND name_class = 'scientific name'";
        # ALIGNMENT
        $query->{'get_stored_alignment'} = "select id, idname, ma, type from ma where id = ?";
	$query->{'get_alignment_descriptions'} = "select id, idname, description from ma where idname = ?"; 
	$query->{'get_stored_alignment_annotation'} = "select id, ma_id, type, annotation from ma_annotation where ma_id = ?"; 

	# Tree
	$query->{'get_stored_tree'} = "select id, idname, tree, type, id, ma_id, description from tree where id = ?";
	$query->{'get_stored_tree_from_ma_id'} = "select id, idname, tree, type, ma_id, description from tree where ma_id = ?";
	$query->{'get_tree_descriptions'} = "select id, idname, type, description, ma_id from tree where idname = ?";

	# Other
	$query->{'get_full_blast_report'} = "select brf.idname, brf.report FROM blast_report_full brf, sequence_type st, db WHERE brf.sequence_type_id = st.id AND db.id = brf.db_id AND brf.idname = ? AND st.type = ? AND db.name = ?";

	$query->{'get_file'} = "select id, data, name, type, location, filename from files where name = ? AND type = ?";
	$query->{'set_new_file'} = "insert into files (id, name, filename, type, location, data) VALUES (NULL, ?, ?, ?, ?, ?)";
	$query->{'delete_file'} = "delete from files where name = ? AND type = ?";

	$query->{'get_all_news'} = "select id, title, short_body, news_date from news order by news_date DESC";
	$query->{'get_recent_news'} = "select id, title, short_body, news_date from news where news_date > curdate() - 7 order by news_date DESC";
	$query->{'get_some_news'} = "select id, title, short_body, news_date from news order by news_date DESC LIMIT ?";
	$query->{'get_news_story'} = "select id, title, body, short_body, news_date from news where id = ?";
	
	return $query;


}

sub get_query
{
	my $self = shift;
	my $query_name = shift;

	return $self->{QUERIES}->{$query_name};
}
sub query
{
	my $self = shift;
	my $query_name = shift;
	my $db_handler = shift;
	if(!$db_handler)
	{
		$db_handler = $self->get_dbh();
	}

	return $db_handler->prepare($self->get_query($query_name));
}

# Access Rights

sub get_id_from_username
{
	my $self = shift;
	my $username = shift;
	
	my $sth = $self->query('get_userid_from_username');
	$sth->execute($username);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{id};
	} else
	{
		return undef;
	}
	
}

sub get_login_info_from_id
{
	my $self = shift;
	my $user_id = shift;

	my $sth = $self->query('login_info');
	$sth->execute($user_id);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref;
	} else
	{
		return undef;
	}
}
sub check_annotation_add_rights
{
	my $self = shift;
	my $login_id = shift;
	my $sth = $self->query('check_annotation_add_rights');
	$sth->execute($login_id);
        if($sth->rows > 0)
        {
                return 1;
        } else
        {
                return 0;
        }
}

sub check_annotation_admin_rights
{
	my $self = shift;
	my $login_id = shift;
	my $sth = $self->query('check_annotation_admin_rights');
	$sth->execute($login_id);
        if($sth->rows > 0)
        {
                return 1;
        } else
        {
                return 0;
        }
}

# Orfs, etc

sub check_orf_existance
{
	my $self = shift;
        my $orfid = shift;
	my $all = shift;

	my $sth;

	if($all)
	{
		$sth = $self->query('check_orf_existance_all');
	} else
	{
	        $sth = $self->query('check_orf_existance');
	}

	$sth->execute($orfid);

        if($sth->rows > 0)
        {
                return 1;
        } else
        {
                return 0;
        }
}

sub delete_orf
{
	my $self = shift;
	my $orfid = shift;
	my $reason = shift;
	my $user_id = shift;

	my $sth = $self->query('delete_orf');
	$sth->execute($reason, $user_id, $orfid);
	if($sth->rows > 0)
	{
		return 1;
	} else
	{
		return 0;
	}
}

sub undelete_orf
{
	my $self = shift;
	my $orfid = shift;
	my $reason = shift;

	my $sth = $self->query('undelete_orf');
	$sth->execute($orfid);
	if($sth->rows > 0)
	{
		return 1;
	} else
	{
		return 0;
	}
	
}


sub update_orf_coordinates
{
	my $self = shift;
	my $orfid = shift;
	my $contig = shift;
	my $start = shift;
	my $stop = shift;
	my $direction = shift;

	my $sth = $self->query('update_orf_coordinates');
	$sth->execute($contig, $start, $stop, $direction, $orfid);
	
}

sub update_orf_sequence
{
	my $self = shift;
	my $orfid = shift;
	my $sequence = shift;


	my $sth = $self->query('update_orf_sequence');
	$sth->execute($sequence, $orfid);

}

sub insert_orf
{
	my $self = shift;
	my $orfid = shift;
	my $contig = shift;
	my $start = shift;
	my $stop = shift;
	my $dir = shift;
	my $sequence = shift;

	my $sth = $self->query('insert_orf');
	$sth->execute($orfid, $contig, $start, $stop, $dir, $sequence, 'N', undef, 'user');

	if($sth->rows > 0)
	{
		return 1;
	} else
	{
		return 0;
	}

}

sub get_orf_nt_sequence
{
	my $self = shift;
        my $orfid = shift;
	my $give_id = shift;
	my $ret_obj = shift;
        my $orfseqh = $self->query('get_orf_sequence');
        $orfseqh->execute($orfid);
        if($orfseqh->rows > 0)
        {
                my $row = $orfseqh->fetchrow_hashref;
                my $sequence = $row->{sequence};
                if($sequence eq '')
                {
                        # Try and get the sequence from the orf coordinates
                        $sequence = $self->get_region($row->{contig}, $row->{start}, $row->{stop} - $row->{start});
                        if($sequence eq '')
                        {
                                $sequence = 'NNN';
                        }
                }
		my $seq;
		if($give_id)
		{
                	$seq = Bio::Seq->new( -seq=> $sequence, -id=>$orfid);
		} else
		{
                	$seq = Bio::Seq->new( -seq=> $sequence, -id=>'orf');
		}
		if($ret_obj)
		{
	                return $seq->translate;
		} else
		{
	                return $seq->seq();
		}
        } else
        {
                return '';
        }
}

sub get_orf_aa_sequence
{
	my $self = shift;
        my $orfid = shift;
	my $give_id = shift;
	my $ret_obj = shift;
        my $orfseqh = $self->query('get_orf_sequence');
        $orfseqh->execute($orfid);
        if($orfseqh->rows > 0)
        {
                my $row = $orfseqh->fetchrow_hashref;
                my $sequence = $row->{sequence};
                if($sequence eq '')
                {
                        # Try and get the sequence from the orf coordinates
                        $sequence = $self->get_region($row->{contig}, $row->{start}, $row->{stop} - $row->{start});
                        if($sequence eq '')
                        {
                                $sequence = 'NNN';
                        }
                }
		my $seq;
		if($give_id)
		{
                	$seq = Bio::Seq->new( -seq=> $sequence, -id=>$orfid);
		} else
		{
                	$seq = Bio::Seq->new( -seq=> $sequence, -id=>'orf');
		}
		if($ret_obj)
		{
	                return $seq->translate;
		} else
		{
	                return $seq->translate->seq();
		}
        } else
        {
                return '';
        }
}


sub get_orf_attributes_hash
{
	my $self = shift;
        my $orfid = shift;
        my $sth = $self->query('get_orf_attrib');
        $sth->execute($orfid);
        if($sth->rows > 0)
        {
                return $sth->fetchrow_hashref;
        } else
        {
                return undef;
        }
}

sub get_orf_sagetags_h
{
	my $self = shift;
        my $orfid = shift;
        my $sth = $self->query('get_orf_sagetags');
        $sth->execute($orfid);
        return $sth;
}

sub get_orf_primary_tag
{
	my $self = shift;
	my $orfid = shift;
	my $sth = $self->query('orf_primary_tag');
	$sth->execute($orfid);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{tagid};
	} else
	{
		return undef;
	}
}

sub check_orf_full_blast_report
{
	my $self = shift;
        my $orfid = shift;
        my $db_name = shift;
        my $sth = $self->query('check_full_blast_report');
        $sth->execute('orf', $db_name, $orfid);
        if($sth->rows > 0)
        {
                return 1;
        } else
        {
                return 0;
        }
}

sub get_top_orf_hit
{
	my $self = shift;
	my $orfid = shift;
	my $cutoff = shift;
	if(!$cutoff)
	{
		$cutoff = 1e-3;
	}

	my $sth = $self->query('get_orf_top_blast_hit');
	$sth->execute($orfid, $cutoff);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref;
	} else
	{
		return undef;
	}
}

sub check_annotation_exists
{
	my $self = shift;
	my %arg = @_;

	my $db = $arg{db};
	my $sequence_type = $arg{sequence_type};;
	my $algorithm = $arg{algorithm};

	my $db_id = $self->get_db_id($db);
	my $sequence_type_id = $self->get_sequence_type_id($sequence_type);
	my $algorithm_id = $self->get_algorithm_id($algorithm);

	my $dbh = $self->dbh();
	if($db_id && $sequence_type_id && $algorithm_id)
	{
		my $sth = $dbh->prepare("select count(*) as hit_counts from blast_results where db = ? AND sequence_type_id = ? AND algorithm = ?");
		$sth->execute($db_id, $sequence_type_id, $algorithm_id);
		return $sth->fetchrow_hashref->{hit_counts};
	}
	return 0;
}

sub get_protfun_annotation
{
	my $self = shift;
	my $orfid = shift;

	my $sth = $self->query('get_blast_annotation');
	$sth->execute($orfid, 'orf', 'protfun', 'protfun');

	return $sth;

	
}

sub get_orf_transmembrane_domains
{
	my $self = shift;
	my $orfid = shift;

	my $sth = $self->query('get_transmembrane_domains');
	$sth->execute($orfid);

	my $row = $sth->fetchrow_hashref;
	return $row->{num_domains};
}

sub get_orf_signal_peptide
{
	my $self = shift;
	my $orfid = shift;

	my $sth = $self->query('get_signal_peptide');
	$sth->execute($orfid);

	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{description};
	} else
	{
		return undef;
	}
	
}
sub get_orf_upstream_starts
{
	my $self = shift;
	my $orfid = shift;

	my $result_arrays;

	my $start_codon;
	my $stop_codon;
	$start_codon->{ATG} = 1;
	$stop_codon->{TAA} = 1;
	$stop_codon->{TAG} = 1;
	$stop_codon->{TGA} = 1;

	my $sth = $self->query('get_contig_subsequence');
	my $orfinfo = $self->get_orf_attributes_hash($orfid);
	my $contig_info = $self->contig_info($orfinfo->{contig});
	
	if($orfinfo->{direction} eq "+")
	{
		my $stop = $orfinfo->{stop};
		my $contig = $orfinfo->{contig};

		my $check = 1;
		my $start_temp = $orfinfo->{stop}-2;
		while($check)
		{
			$start_temp = $start_temp - 3;
			if($start_temp < 1)
			{
				$check = 0;
				next;
			}
			$sth->execute($start_temp, 3, $contig);
			if($sth->rows > 0)
			{
				my $codon = uc($sth->fetchrow_hashref->{seq});
				if($stop_codon->{$codon})
				{
					# This is a stop codon, stop checking
					$check = 0;
				} elsif($start_codon->{$codon})
				{
					# This is a start codon so add it to the return array
					my $hash = { 'contig'=>$contig, 'start'=>$start_temp, 'stop'=>$stop, 'direction'=>"+" };
					push(@{$result_arrays}, $hash);
				}
			} else
			{
				$check = 0;
			}
		}
	} elsif($orfinfo->{direction} eq "-")
	{
		my $stop = $orfinfo->{start};
		my $contig = $orfinfo->{contig};
	
		my $check = 1;
		my $start_temp = $orfinfo->{start} ;
		while($check)
		{
			$start_temp = $start_temp + 3;
			if($start_temp > $contig_info->{contig_length})
			{
				$check = 0;
				next;
			}
			$sth->execute($start_temp, 3, $contig);
			if($sth->rows > 0)
			{
				my $codon = uc($sth->fetchrow_hashref->{seq});
				$codon = reverse($codon);
				$codon =~ tr/ACTG/TGAC/;
				if($stop_codon->{$codon})
				{
					# This is a stop codon, stop checking
					$check = 0;
				} elsif($start_codon->{$codon})
				{
					# This is a start codon so add it to the return array, add 2 to new start to get the whole start codon
					my $hash = { 'contig'=>$contig, 'start'=>$stop, 'stop'=>$start_temp+2, 'direction'=>"-" };
					push(@{$result_arrays}, $hash);
				}

			} else
			{
				$check = 0;
			}
		}
	}

	return $result_arrays;
}
sub get_upstream_sequence
{
	my $self = shift;
	my $contig = shift;
	my $start = shift;
	my $size = shift;
	my $direction = shift;

	my $seq;
	if(!defined($direction) || $direction eq "+")
	{
		my $new_start = $start - $size;
		my $dif = 0;
		if($new_start < 1)
		{
			$dif = $new_start; 
			$new_start = 1;
		}

		$seq = uc($self->get_region($contig, $new_start, $size + $dif));
		return $seq;
	} elsif($direction eq "-")
	{
		$seq = $self->reverse_complement(uc($self->get_region($contig, $start, $size)));
		return $seq;
	}
}
sub get_downstream_sequence
{
	my $self = shift;
	my $contig = shift;
	my $start = shift;
	my $size = shift;
	my $direction = shift;

	my $seq;
	if(!defined($direction) || $direction eq "+")
	{
		$seq = uc($self->get_region($contig, $start, $size));
		return $seq;
	} elsif($direction eq "-")
	{
		my $new_start = $start - $size;
		my $dif = 0;
		if($new_start < 1)
		{
			$dif = $new_start; 
			$new_start = 1;
		}

		$seq = uc($self->get_region($contig, $new_start, $size + $dif));
		return $self->reverse_complement($seq);
	
	}
	return undef;
}

sub get_supercontig_coords_from_contig
{
	my $self = shift;
        my $contig_number = shift;
        my $start = shift;
        my $stop = shift;
        my $minimum_gap_fg = shift;

	if(!$contig_number)
	{
		return undef;
	}
	if(!$start)
	{
		$start = 1;
	}
	if(!$stop)
	{
		$stop = 1;
	}

        if(!$minimum_gap_fg)
        {
                $minimum_gap_fg = 1;
        }

        if($contig_number =~ /^\d+$/)
        {
                # Do nothing
        } else
        {
                ($contig_number) = $contig_number =~ /(\d+)/;
        }
        my $sth = $self->query('contig_info');
        my ($super_id, $new_start, $new_stop);
        $sth->execute($contig_number);
	if(my $row = $sth->fetchrow_hashref)
	{
		my $start_base = 0;

	        if($minimum_gap_fg)
	        {
			$start_base = $row->{modified_contig_start_base};
	        } else
	        {
	                $start_base = $row->{contig_start_super_base};
	        }

		$new_start = $start +$start_base;
		$new_stop  = $stop + $start_base;

	        $super_id = $row->{super_id};
	        return ($super_id, $new_start, $new_stop);
	} else
	{
		return (undef, undef, undef);
	}
}

sub get_orf_feature_results
{
	my $self = shift;
	my $orf = shift;
	my $eval = shift;

	my $sth = $self->query('get_orf_feature_results');
	$sth->execute($orf, $eval);
	return $sth;

}
sub get_orf_feature_results_reduced
{
	my $self = shift;
	my $orf = shift;
	my $eval = shift;

	my $sth = $self->query('get_orf_feature_results_reduced');
	$sth->execute($orf, $eval);
	return $sth;

}

sub get_orf_feature_results_list
{
	my $self =  shift;
	my $orf = shift;
	my $eval = shift;

	my $result = $self->get_orf_feature_results($orf, $eval);
	my $ret_string = '';
	while(my $row = $result->fetchrow_hashref)
	{
		if($row->{hit_name} =~ /\w/)
		{
			$ret_string .= "|" . $row->{hit_name};
		} elsif($row->{description} =~ /\w/)
		{
			$ret_string .= "|" . $row->{description};
		}
	}

	return $ret_string;
}
sub get_orf_feature_results_list_reduced
{
	my $self =  shift;
	my $orf = shift;
	my $eval = shift;

	my $result = $self->get_orf_feature_results_reduced($orf, $eval);
	my $ret_string = '';
	while(my $row = $result->fetchrow_hashref)
	{
		if($row->{description} =~ /\w/ && $row->{description} ne 'no description')
		{
			$ret_string .= "|" . $row->{description};
		} elsif($row->{hit_name} =~ /\w/)
		{
			$ret_string .= "|" . $row->{hit_name};
		}
	}

	return $ret_string;
}

sub get_region
{
	my $self = shift;
        my $name = shift;
        my $start = shift;
        my $length = shift;

        # Check if the name is just a number, if it is, it might then really be contig_(number)
        my $sth = $self->query('check_contig_exists');
        $sth->execute($name);
        if($sth->rows > 0)
        {
                # do nothing
        } else
        {
                ($name) = $name =~ /(\d+)/;
        }
        if($start < 1)
        {
                $start = 1;
        }

        $sth = $self->query('get_contig_subsequence');
#	my $length = ($stop - $start)+1;
        $sth->execute($start, $length, $name);
        if($sth->rows > 0)
        {
                my $row = $sth->fetchrow_hashref;
                return $row->{seq};
        } else
        {
		# Check for contig_
		$sth->execute($start, $length, 'contig_' . $name);
		if($sth->rows > 0)
		{
			my $row = $sth->fetchrow_hashref;
			return $row->{seq};
		} else
		{
                	return '';
		}
        }
}


sub get_orfs_by_keyword
{
	my $self = shift;
	my $keyword = shift;

	my $dbh = $self->dbh();
	my $word_quoted = $dbh->quote($keyword);
        $word_quoted =~ s/^\'//;
        $word_quoted =~ s/\'$//;
	$word_quoted = lc($word_quoted);
	
	my $sth = $dbh->prepare("select DISTINCT orfs.orfid from annotation, orfs where orfs.orfid = annotation.orfid AND orfs.delete_fg = 'N' AND annotation.delete_fg = 'N' AND annotation.private_fg = 'N' AND position('$word_quoted' IN lower(annotation.annotation) ) > 0 ");

	$sth->execute();
	my $orf_array;
	if($sth->rows > 0)
	{
		while(my $row = $sth->fetchrow_hashref)
		{
			push(@{$orf_array}, $row->{orfid});
		}

		return $orf_array;

	} else
	{
		return undef;
	}


}

sub get_orf_by_domain
{
	my $self = shift;
	my $keyword = shift;
	my $evalue = shift;

	if(!defined($evalue))
	{
		$evalue = 1e-3;
	}

	my $dbh = $self->dbh();

	my $query = 
"SELECT distinct br.idname as orfid
from blast_results br,
db,
sequence_type st
where st.id = br.sequence_type_id
AND db.id = br.db
AND st.type = 'orf'
AND db.name IN ( 'interpro', 'Pfam_ls')
AND (br.evalue < " . $dbh->quote($evalue) . " OR br.evalue is NULL)
AND position(" . $dbh->quote(lc($keyword)) . " in lower(concat(IFNULL(br.description, ''), '!!', IFNULL(br.hit_name, ''), '!!', IFNULL(br.accession_number, ''), '!!', IFNULL(br.primary_id, '') )))  > 0
";

	warn($query);
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $orf_array;
	if($sth->rows > 0)
	{
		while(my $row = $sth->fetchrow_hashref)
		{
			push(@{$orf_array}, $row->{orfid});
		}

		return $orf_array;

	} else
	{
		return undef;
	}
	


}

# Annotation
                                                                                                                                                
sub get_evidence_code_id
{
	my $self = shift;
        my $desc = shift;
        my $sth = $self->query('get_evidence_code_id');
        $sth->execute($desc, $desc);
        if($sth->rows > 0)
        {
                return $sth->fetchrow_hashref->{id};
        } else
        {
                return 0;
        }
}

sub get_newest_annotation
{
	my $self = shift;
        my $orfid = shift;
        my $sth = $self->query('get_newest_annotation');
        $sth->execute($orfid);
        if($sth->rows > 0)
        {
                return $sth->fetchrow_hashref->{annotation};
        } else
        {
                return 'No annotation';
        }
}

sub add_annotation
{
	my $self = shift;
	my $user_id = shift;
	my $orfid = shift;
	my $annotation = shift;
	my $notes = shift;
	my $delete_fg = shift;
	my $blessed_fg = shift;
	my $qualifier = shift;
	my $with_from = shift;
	my $aspect = shift;
	my $object_type = shift;
	my $evidence_code = shift;
	my $private_fg = shift;
	
	my $sth = $self->query('add_annotation');

	$sth->execute($user_id, $orfid, $annotation, $notes, $delete_fg,$blessed_fg, $qualifier, $with_from, $aspect, $object_type, $evidence_code, $private_fg );
	if($sth->rows)
	{
		return 1;
	} else
	{
		return 0;
	}

#	"insert into annotation (userid, orfid, annotation, notes, delete_fg, blessed_fg, qualifier, with_from, aspect, object_type, evidence_code, private_fg) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
}


# Sage


sub has_sage
{
	my $self = shift;
	
	my $dbh = $self->dbh;
	
	my $sth = $dbh->prepare("select count(tagid) as num_tags from sage_tags");
	$sth->execute();
	if($sth->fetchrow_hashref->{num_tags} > 0)
	{
		return 1;
	} else
	{
		return 0;
	}
}

sub get_sage_access_libraries
{
	my $self = shift;
        my $login_id = shift;
        my $libh = $self->query('get_library_access');
        $libh->execute($login_id);
        my $access_list = "'0'";
        while(my $row = $libh->fetchrow_hashref)
        {
                $access_list .= ", '" . $row->{library} . "'";
        }
        return $access_list;
}

sub check_sage_access_library
{
	my $self = shift;
	my $login_id = shift;
	my $lib_check = shift;

	my $libh = $self->query('get_library_access');
	$libh->execute($login_id);

	while(my $row = $libh->fetchrow_hashref)
	{
		if($row->{library} eq $lib_check)
		{
			return 1;
		}
	}
	return 0;
}
sub get_sage_access_libraries_array
{
        my $self = shift;
        my $login_id = shift;
        my $libh = $self->query('get_library_access');
	my $ret_array;

        $libh->execute($login_id);
	my $detailh = $self->query('sage_library_detail');

        while(my $row = $libh->fetchrow_hashref)
        {
               	push(@{$ret_array}, $row->{library});
        }

        return $ret_array;
}

sub get_sage_libraries_array_from_results
{
	my $self = shift;

	my $retval;
	my $dbh = $self->dbh;
	my $sth = $dbh->prepare("select distinct library from sage_results");
	$sth->execute();
	while(my $row = $sth->fetchrow_hashref)
	{
		push(@$retval, $row->{library});
	}

	return $retval;	
}

sub get_sage_libraries_array_from_names
{
	my $self = shift;

	my $retval;
	my $dbh = $self->dbh;
	my $sth = $dbh->prepare("select library, name, short_name, priority from sage_library_names");
	$sth->execute();

	while(my $row = $sth->fetchrow_hashref)
	{
		push(@$retval, $row->{library});
	}

	return $retval;
}

sub get_sage_libraries_array
{
	my $self = shift;

	my $ret_array;
	my $libhash;
	my $array1 = $self->get_sage_libraries_array_from_names();
	my $array2 = $self->get_sage_libraries_array_from_results();
	
	foreach my $lib(@$array1)
	{
		$libhash->{$lib} = 1;
	}
	foreach my $lib(@$array2)
	{
		$libhash->{$lib} = 1;
	}

	while(my ($key, $val) = each (%$libhash))
	{
		push(@$ret_array, $key);
	}

	return $ret_array;

}
sub get_sage_result_list
{
	my $self = shift;
	my $libraries = shift;
	my $tagid = shift; # Optional

	my $dbh = $self->dbh;
	my $library_selected = '';
	my $library_select = 'select ';

	foreach my $lib (@$libraries)
	{
		$library_selected .= ', ' . $dbh->quote($lib);
		$library_select .= $lib . ".result as " . $lib . ", ";
	}
	$library_select .= " st.tagid, st.sequence from sage_tags st";
	foreach my $lib (@$libraries)
	{
		$library_select .= ', sage_results ' . $lib;
	}

	$library_select .= " WHERE st.tagid = st.tagid ";

	foreach my $lib (@$libraries)
	{
		$library_select .= ' AND st.tagid = '  . $lib . '.tagid AND ' . $lib . '.library = ' . $dbh->quote($lib) ;
	}

	if($tagid)
	{
		$library_select .= ' AND st.tagid = ' . $dbh->quote($tagid);
	}


	my $sth = $dbh->prepare($library_select);
	$sth->execute();
	return $sth;

}

sub get_sage_library_short_name
{
	my $self = shift;
	my $lib = shift;

	my $detailh = $self->query('sage_library_detail');
	$detailh->execute($lib);
	my $row = $detailh->fetchrow_hashref;
	if($row)
	{
		return $row->{short_name};
	} else
	{
		return $lib;
	}
}

sub get_sage_library_info
{
	my $self = shift;
	my $lib = shift;

	my $detailh = $self->query('sage_library_detail');
	$detailh->execute($lib);
	my $row = $detailh->fetchrow_hashref;
	if($row)
	{
		return $row;
	} else
	{
		return undef;
	}

}
sub get_sage_description_line
{
	my $self = shift;
	my $tagid = shift;
	my $type = shift;
	my $login_id = shift;

	# Check if this tag has an orf
	my $orfh = $self->get_sage_orf_info($tagid);
	if($orfh)
	{
		my $tagtype = $self->get_tagtype($tagid);
		my $desc = "$tagid|$tagtype|orf:" . $orfh->{orfid};
		return $desc;
	} else
	{
		return "$tagid|UK";
	}

}
sub get_sage_description_line_old
{
	my $self = shift;
	my $tag_id = shift;
	my $type = shift;
	my $login_id = shift;
	my $display_type = shift;

	if(!$display_type)
	{
		$display_type = 'oneline';
	}

	my $access_list = $self->get_sage_access_libraries($login_id);

	my $dbh = $self->dbh();
	my $sth = $dbh->prepare("select sr.library, sr.result, sln.short_name from sage_results sr, sage_library_names sln where sr.library = sln.library AND sr.library IN ($access_list) AND sr.tagid = ? order by sr.library");
	# Find out how many times it maps
	$sth->execute($tag_id);
	if($sth->rows > 0)
	{
		# Get each result and return
		my $ret_val = $tag_id . ":" . $self->sage_tag_map_count($tag_id) . ' ';

		# If the type if percent, then we need to find totals
		my $total_hash = $self->get_sage_library_total_filtered();
		if($type eq 'percent')
		{
		}
		while(my $row = $sth->fetchrow_hashref)
		{
			$ret_val .=  $row->{short_name};
			if($display_type eq 'oneline')
			{
				$ret_val .= '[' ;
			} else
			{
				$ret_val .= '  ';
			}

			if(lc($type) eq 'percent')
			{
				$ret_val .= sprintf("%.3f",  ($row->{result} / $total_hash->{$row->{library}}) * 100);
			} else
			{
				$ret_val .= $row->{result};
			}
			if($display_type eq 'oneline')
			{
				$ret_val .=  ']';
			} else
			{
				$ret_val .= '<br>';
			}
		}
		return $ret_val;
	} else
	{
		return undef;
	}
}

sub get_sage_over_description
{
	my $self = shift;
	my $tag_id = shift;
	my $type = shift;
	my $login_id = shift;

	my $access_list = $self->get_sage_access_libraries($login_id);

	my $dbh = $self->dbh();
	my $sth = $dbh->prepare("select sr.library, sr.result, sln.short_name from sage_results sr, sage_library_names sln where sr.library = sln.library AND sr.library IN ($access_list) AND sr.tagid = ? order by sr.library");
	# Find out how many times it maps
	$sth->execute($tag_id);
	if($sth->rows > 0)
	{
		# Get each result and return
		my $ret_val;
		$ret_val .= "SAGE Tag $tag_id<br>";

		# Find if it has an orf
		my $orfinfo = $self->get_sage_orf_info($tag_id);
		if($orfinfo)
		{
			$ret_val .= $orfinfo->{tagtype} . ' to ORF ' . $orfinfo->{orfid} . "<br>";
		} else
		{
			# Nothing
		}


		$ret_val .= $self->sage_tag_map_count($tag_id) . ' total matches to genome contigs<br><br>';

		# If the type if percent, then we need to find totals
		my $total_hash = $self->get_sage_library_total_filtered();
			
		# Create array 
		my $expr_array;
		my $lib_array;
		while(my $row = $sth->fetchrow_hashref)
		{
			if(lc($type) eq 'percent')
			{
				push(@$expr_array, sprintf("%.5f",  ($row->{result} / $total_hash->{$row->{library}}) * 100));
			} else
			{
				push(@$expr_array,$row->{result});
			}
			push(@$lib_array, $row->{short_name});
		}

		my $color_expr = $self->color_median_expr($expr_array);
		my $count = 0;
		$ret_val .= "<table width=60%>";

		foreach my $result_row(@$color_expr)
		{
			$ret_val .= "<tr><td>" . $lib_array->[$count] . "</td>" . $result_row . "</tr>";
			$count++;
		}

		$ret_val .= "</table";
		return $ret_val;
	} else
	{
		return undef;
	}
}

sub sage_tag_max_expr
{
	my $self = shift;
	my $tagid = shift;
	my $login_id = shift;
	if(!$login_id)
	{
		$login_id = undef;
	}

	my $access_list = $self->get_sage_access_libraries($login_id);

	my $sth = $self->dbh->prepare("select max(result) as max_result from sage_results where library IN ($access_list) AND tagid = ?");
	$sth->execute($tagid);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{max_result};
	}

}

sub sage_tag_map_count
{
	my $self = shift;
	my $tagid = shift;
	
	my $sth = $self->query('sage_count_map');
	$sth->execute($tagid);
	
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{num_map};
	} else
	{
		return 0;
	}
}

sub get_sage_library_total
{
	my $self = shift;

	my $sth = $self->query('sage_library_totals');
	$sth->execute();
	my $ret_hash;
	while(my $row = $sth->fetchrow_hashref)
	{
		$ret_hash->{$row->{library}} = $row->{total};
	}
	return $ret_hash;
}

sub get_sage_library_total_filtered
{
        my $self = shift;
                                                                                                                           
        my $sth = $self->query('sage_library_totals_filtered');
        $sth->execute();
        my $ret_hash;
        while(my $row = $sth->fetchrow_hashref)
        {
                $ret_hash->{$row->{library}} = $row->{total};
        }
        return $ret_hash;

}

sub get_one_sage_library_total
{
	my $self = shift;
	my $library = shift;

	my $sth = $self->query('sage_library_total');
	$sth->execute($library);

	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{total};
	} else
	{
		return 0;
	}
}

sub get_one_sage_library_total_filtered
{
        my $self = shift;
        my $library = shift;
                                                                                                                            
        my $sth = $self->query('sage_library_total_filtered');
	$sth->execute($library);
        if($sth->rows > 0)
        {
                return $sth->fetchrow_hashref->{total};
        } else
        {
                return 0;
        }
}

sub get_sage_orf_info
{
	my $self = shift;
	my $tagid = shift;

	my $sth = $self->query('sagetag_orf_assignment');
	$sth->execute($tagid);
	if($sth->rows > 0)
	{

		return $sth->fetchrow_hashref;
	} else
	{
		return undef;
	}
	
}

sub get_sage_orf_info_list
{
	my $self = shift;
	my $tagid = shift;

	my $sth = $self->query('sagetag_orf_assignment');
	$sth->execute($tagid);
	if($sth->rows > 0)
	{

		return $sth;
	} else
	{
		return undef;
	}
	
}

sub get_sage_by_terms
{
	my $self = shift;
	my $terms = shift;
	my $access_libs = shift;

	my $dbh = $self->dbh();
	$terms = $dbh->quote($terms);
	$terms =~ s/^\'//;
	$terms =~ s/\'$//;

	# check annotation
	my $sth = $dbh->prepare("
	select distinct ot.tagid
	from (
	select distinct os.tagid from orftosage os, 
	annotation an where an.orfid = os.orfid AND an.private_fg = 'N' AND an.annotation like '%$terms%'
	AND os.tagid IN (select distinct tagid from sage_results where result > 0 AND library IN ($access_libs))
	UNION
	select distinct os.tagid from orftosage os, blast_results br where br.idname = os.orfid
	AND br.sequence_type_id = 2 AND br.db IN (6,2,5,4,3) 
	AND os.tagid IN (select distinct tagid from sage_results where result > 0 AND library IN ($access_libs))
	AND br.evalue < 1e-4
	AND br.description like '%$terms%'
	UNION
	select distinct os.tagid from orftosage os, blast_results br where br.idname = os.orfid
	AND br.sequence_type_id = 2 AND br.db IN (6,2,5,4,3)
	AND os.tagid IN (select distinct tagid from sage_results where result > 0 AND library IN ($access_libs))
	AND br.evalue < 1e-4
	AND br.accession_number = ?) AS ot order by tagid");

	$sth->execute($terms);
	my $ret_array;
	while(my $row = $sth->fetchrow_hashref)
	{
		push(@{$ret_array}, $row->{tagid});
	}
	return $ret_array;

}

sub get_sagetags_by_orfid
{
	my $self = shift;
	my $orfid = shift;
	
	my $sth = $self->query('sage_by_orfid');
	$sth->execute($orfid);
	if($sth->rows > 0)
	{
		my $ret_array;
		while(my $row = $sth->fetchrow_hashref)
		{
			push(@{$ret_array}, $row->{tagid});
		}
		return $ret_array;
	} else
	{
		return undef;
	}	
}
sub get_contig_desc
{
	my $self = shift;
	my $contig_id = shift;

	my $dbh = $self->dbh;
	my $getdesch = $dbh->prepare("select idname, evalue, description, accession_number from blast_results where sequence_type_id = 5 AND idname = ? order by evalue LIMIT 1");

	$getdesch->execute($contig_id);
	if($getdesch->rows > 0)
	{
		my $descrow = $getdesch->fetchrow_hashref;
		return "CONTIG BLASTX: " . $descrow->{description} . " ACC " . $descrow->{accession_number} . " at E-Value " . $descrow->{evalue};
	} else
	{
		$getdesch->execute('contig_' . $contig_id);
		if($getdesch->rows > 0)
		{
			my $descrow = $getdesch->fetchrow_hashref;
			return "CONTIG BLASTX: " . $descrow->{description} . " ACC " . $descrow->{accession_number} . " at E-Value " . $descrow->{evalue};
		} else
		{
			return undef;
		}
	}
}
sub get_sage_contig_desc
{
	my $self = shift;
	my $tagid = shift;

	my $dbh = $self->dbh;

	my $getmaph = $dbh->prepare("select tagid, contig, start, stop, direction, id from tagmap where tagid = ?");
	my $getdesch = $dbh->prepare("select idname, evalue, description, accession_number from blast_results where sequence_type_id = 5 AND idname = ? order by evalue LIMIT 1");
	$getmaph->execute($tagid);

	if($getmaph->rows == 1)
	{
		my $row = $getmaph->fetchrow_hashref;
		my ($contig_id) = $row->{contig} =~ /contig_(\d+)/;
		return $self->get_contig_desc($contig_id);
				
	} elsif($getmaph->rows > 1)
	{
		return "Multiple Map Locations";

	} else
	{
		return undef;
	}

}

sub get_sage_results_hash
{
        my $self = shift;
        my $tag_id = shift;
        my $type = shift;
        my $login_id = shift;

        my $access_list = $self->get_sage_access_libraries($login_id);

        my $dbh = $self->dbh();
        my $sth = $dbh->prepare("select sr.library, sr.result, sln.short_name from sage_results sr, sage_library_names sln where sr.library = sln.library AND sr.library IN ($access_list) AND sr.tagid = ? order by sr.library");

	my $ret_hash;

        # Find out how many times it maps
        $sth->execute($tag_id);
        if($sth->rows > 0)
        {
                # Get each result and return

                # If the type if percent, then we need to find totals
                my $total_hash = $self->get_sage_library_total_filtered();
                while(my $row = $sth->fetchrow_hashref)
                {
                        if(lc($type) eq 'percent')
                        {
                                $ret_hash->{$row->{library}} = sprintf("%.3f",  ($row->{result} / $total_hash->{$row->{library}}) * 100);
                        } else
                        {
                                $ret_hash->{$row->{library}} = $row->{result};
                        }
                }

                return $ret_hash;
        } else
        {
                return undef;
        }


}


sub get_sage_sequence
{
	my $self = shift;
	my $tagid = shift;

	my $sth = $self->query('sage_sequence');
	$sth->execute($tagid);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{sequence};
	} else
	{
		return undef;
	}
}

sub check_sagetag_exists
{
	my $self = shift;
	my $tagid = shift;
	my $login_id = shift;

	my $access_list = $self->get_sage_access_libraries($login_id);
	
	my $dbh = $self->dbh;
	my $sth = $dbh->prepare("select distinct tagid from sage_results where library IN ($access_list) AND tagid = ? AND result > 0");
	$sth->execute($tagid);
	if($sth->rows > 0)
	{
		return 1;
	} else
	{
		return 0;
	}
}

sub get_sagetag_assignment_desc
{
	my $self = shift;
	my $tagid = shift;

	my $orf = $self->get_sage_orf_info($tagid);
	my $annotation;

	if($orf)
	{
		# We have an orf that this is assigned to 

		# Check if this orf has an annotation
		$annotation = $self->get_newest_annotation($orf->{orfid});
		if($annotation ne "No annotation")
		{
			return $annotation;	
		}
		my $orfhash = $self->get_top_orf_hit($orf->{orfid});
		if($orfhash)
		{
			return $orfhash->{description};
		}
	} else
	{
		# Check blast of sage tag
		return $self->get_sage_top_blast_hit($tagid);
	}
	
}

sub get_sage_top_blast_hit
{
	my $self = shift;
	my $tagid = shift;
	
	my $sth = $self->query('sage_top_blast_tag');
	$sth->execute($tagid);
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		return "BLASTN of SAGETAG : " . $row->{hit_name} . '|' . $row->{description} . '|' . $row->{evalue};
	} else
	{
		return undef;
	}


}




sub color_tagtype
{
	my $self = shift;
	my $tagid = shift;

	my $orf = $self->get_sage_orf_info($tagid);

	if($orf)
	{
		if($orf->{tagtype} eq 'Primary Sense Tag')
		{
			return '<td bgcolor=darkblue><center><font color=yellow>PS</font></center></td>';
		} elsif($orf->{tagtype} eq 'Alternate Sense Tag')
		{
			return '<td bgcolor=blue><center><font color=yellow>AS</font></center></td>';
		} elsif($orf->{tagtype} eq 'Primary Antisense Tag')
		{
			return '<td bgcolor=green><center><font color=white>PA</font></center></td>';
		} elsif($orf->{tagtype} eq 'Alternate Antisense Tag')
		{
			return '<td bgcolor=yellow><center><font color=black>AA</font></center></td>';
		} 
	} else
	{
	        return '<td bgcolor=black><center><font color=white>UK</font></center></td>';
	}

}

sub get_tagtype
{
	my $self = shift;
	my $tagid = shift;

	my $orf = $self->get_sage_orf_info($tagid);

	if($orf)
	{
		if($orf->{tagtype} eq 'Primary Sense Tag')
		{
			return 'PS';
		} elsif($orf->{tagtype} eq 'Alternate Sense Tag')
		{
			return 'AS';
		} elsif($orf->{tagtype} eq 'Primary Antisense Tag')
		{
			return 'PA';
		} elsif($orf->{tagtype} eq 'Alternate Antisense Tag')
		{
			return 'AA';
		}
	} else
	{
		return 'UK';
	}

}

sub color_expression
{
	my $self = shift;
	my $score = shift;
	my $expr = shift;
                                                                                                                                                                                                                                                      
	my $max_score = 4;
	if($score > 4)
	{
		$score = 4;
	}
	my $unit_score = 255/ $max_score;
	$score = $score * $unit_score;
	# Reverse this, 255 -> 0, 0 -> 255
	my $revscore = abs($score - 255);
	my $color = sprintf("%X", $score);
	my $revcolor = sprintf("%X", $revscore);
	my $retval =  '<td bgcolor="#' . $revcolor . $revcolor . $revcolor . '">';
	my $font_color;

	if($score > 128)
	{
		$font_color = 'yellow';
	} else
	{
		$font_color = 'black';
	}

	$retval .= "<font color=$font_color>$expr</font></td>";

	return $retval;
}

sub color_median_expr
{
	my $self = shift;
	my $expression = shift;

	my $ret_array;

	my $tmp_array;
	
	# Log transform and add 1
#	foreach my $expr (@$expression)
#	{
#		push(@$tmp_array, log($expr
#	}

	# find out the median
	my $mid_id = int(scalar @$expression / 2);

	# sort the array numerically
	my @sorted = sort{$a <=> $b} @$expression;

	my $median = $sorted[$mid_id];

	my $min = $sorted[0];
	my $max = $sorted[(scalar @$expression)-1];
	my $total_vals = scalar @$expression;

	my %color_hash;
	$color_hash{0} = '#808000';
	$color_hash{1} = '#008000';
	$color_hash{2} = '#000000';
	$color_hash{3} = '#000000';
	$color_hash{4} = '#800000';
	$color_hash{5} = '#FF0000';
	$color_hash{6} = '#FFFFFF';


	# Middle values we color black, low values we color green then yellow, high values we color maroon then red

	my $difference = $max - $min;
	my $unit = 0;
	if($difference == 0)
	{
	}else
	{
		$unit = 5 / $difference ;
	}
	my $font_color;

	foreach my $expr (@$expression)
	{
		if($difference == 0)
		{
			push(@$ret_array, '<td bgcolor=' . $color_hash{3} . '>' . "<font color=white>$expr</font></td>");
			
		} else
		{
			my $score = int(($expr - $min) * $unit);

			push(@$ret_array, '<td bgcolor=' . $color_hash{$score} . '>' . "<font color=white>$expr</font></td>");
		}
#		if($expr < $median)
#		{
			# Print it a degree of Red
#	        	my $score = $expr * $low_unit;
#		        # Reverse this, 255 -> 0, 0 -> 255
#		        my $revscore = abs($score - 255);
#		        my $color = sprintf("%X", $score);
#		        my $revcolor = sprintf("%X", $revscore);
#		        if($score > 128)
#		        {
#		                $font_color = 'white';
#		        } else
#		        {
#		                $font_color = 'black';
#		        }

#			push(@$ret_array, '<td bgcolor=#' . $revcolor . '00' .  '00' . '>' . "<font color=$font_color>$expr</font></td>");
			
#		} elsif($expr > $median)
#		{
			# Print it a degree of Green
#			 my $score = $expr * $high_unit;
                        # Reverse this, 255 -> 0, 0 -> 255
#                       my $revscore = abs($score - 255);
#                        my $color = sprintf("%X", $score);
#                        my $revcolor = sprintf("%X", $revscore);
#                        if($score > 128)
#                        {
#                                $font_color = 'white';
#                        } else
#                        {
#                                $font_color = 'white';
#                        }
                                                                                                                           
#                        push(@$ret_array, '<td bgcolor=#' . '00' . $color .   '00' . '>' . "<font color=$font_color>$expr</font></td>");

#		} else
#		{
			# Print it as Black
#			push(@$ret_array, '<td bgcolor=black><font color=white>' . $expr . '</font></td>');
#		}

	}
	return $ret_array;


}

sub color_rvalue
{
	my $self = shift;
	my $score = shift;
	my $rval = $score;
	my $max_score = 400;
	if($score > 400)
	{
		$score = 400;
	}
	my $unit_score = 255/ $max_score;
	$score = $score * $unit_score;
	# Reverse this, 255 -> 0, 0 -> 255
	my $revscore = abs($score - 255);
	my $color = sprintf("%X", $score);
	my $revcolor = sprintf("%X", $revscore);
	my $retval =  '<td bgcolor="#' . $revcolor . $revcolor . $revcolor . '">';
	my $font_color;
	if($score > 128)
	{
		$font_color = 'yellow';
	} else
	{
		$font_color = 'black';
	}
	$retval .= "<font color=$font_color>$rval</font></td>";
	return $retval;

}

sub color_clustervalue
{
	my $self  = shift;
	my $score = shift;
	if(!$score)
	{
		$score = 0;
	}
	my $cluster = $score;
	my $max_score = param('num_clusters');
	if($score > 10)
	{
		$score = 10;
	}
	my $unit_score = 255/ $max_score;
	$score = $score * $unit_score;
	# Reverse this, 255 -> 0, 0 -> 255
	my $revscore = abs($score - 255);
	my $color = sprintf("%X", $score);
	my $revcolor = sprintf("%X", $revscore);
	my $retval =  '<td bgcolor="#' . $color . $color . $revcolor . '">';
	my $font_color = 'black';
	$retval .= "<center><font color=$font_color><b>$cluster</b></font></center></td>";
	return $retval;
}

sub sage_orf_tagtypes_ref
{
	my $self = shift;
	my $orfid = shift;
	my $tagtype = shift;
	my $login_id = shift;

	my $libs = $self->get_sage_access_libraries($login_id);

	my $query = "select DISTINCT os.tagid from orftosage os, sage_results sr 
			where os.orfid = ? AND os.tagtype = ? 
			AND sr.result > 0 AND sr.tagid = os.tagid AND sr.library IN ($libs)";
	#my $sth = $self->query('sage_orf_tagtypes');
	my $dbh = $self->dbh;
	my $sth = $dbh->prepare($query);
	$sth->execute($orfid, $tagtype);
	return $sth;
	
}
sub sage_ref_to_html
{
	my $self = shift;
	my $hand = shift;
	my $type = shift;
	my $login_id = shift;

	if(!$login_id)
	{
		$login_id = undef;
	}

	my $retval = $type . "<p>";
	while(my $row = $hand->fetchrow_hashref)
	{
		if($self->sage_tag_max_expr($row->{tagid}, $login_id) > 0)
		{
			$retval .= $self->sagetag_link($row->{tagid}) . "<br>";
		}
	}
	return $retval;
	
}

sub get_rval_hash
{
	my $self = shift;
	my $tagref = shift;

	my $rval_hash;
	my $lib_total_hash;
	# tagref is a hashref with the key as a tagid and the value as an array of the results

	my $grandtagcount;

	# Get totals
	while(my ($key, $val) = each(%{$tagref}))
	{
		my $lib_id = 1;
		foreach my $tag_count (@{$val})
		{
			$grandtagcount += $tag_count;
			$lib_total_hash->{$lib_id} += $tag_count;
			$lib_id++;
		}
	}

	while(my ($key, $val) = each(%{$tagref}))
	{
		my $tagtotal = 0;
		foreach my $tag_count (@{$val})
		{
			$tagtotal += $tag_count;
		}

		my $lib_id = 1;
		my $tagfrequency = $tagtotal / $grandtagcount;

		foreach my $tag_count (@{$val})
		{
			my $tempR = 0;
			if($tag_count > 0)
			{
				$tempR = $tag_count / ($lib_total_hash->{$lib_id} * $tagfrequency);
				$tempR = $self->log10($tempR);
				$tempR = $tag_count * $tempR;
				$rval_hash->{$key} += $tempR;
			}
			$lib_id++;
		}
	}
	return $rval_hash;


}

# News

sub get_news_result
{
	my $self = shift;
	my $type = shift;

	my $sth;

	if($type eq 'all')
	{
		$sth = $self->query('get_all_news');
		$sth->execute();
	} elsif($type eq 'current')
	{
		$sth = $self->query('get_recent_news');
		$sth->execute();
	} elsif($type =~ /\d+/)
	{
		$sth = $self->query('get_some_news');
		$sth->execute($type);
	} else
	{
		$sth = $self->query('get_some_news');
		$sth->execute(10);	
	}

	return $sth;
	
}


sub get_news_story_hash
{
	my $self = shift;
	my $newsid = shift;
	
	my $sth = $self->query('get_news_story');
	$sth->execute($newsid);

	return $sth->fetchrow_hashref;


}

# Files

sub get_file
{
	my $self = shift;
	my $name = shift;
	my $type = shift;
	
	my $sth = $self->query('get_file');
	$sth->execute($name, $type);
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		if($row->{location})
		{
			my $retval;
			open(FILE, $row->{location});
			while(<FILE>)
			{
				$retval .= $_;
			}
			return ($row->{filename}, $retval);
			
		} else
		{
			return ($row->{filename}, $row->{data});
		}
	} else
	{
		return undef;
	}
}

sub set_new_file
{
	my $self = shift;
	my $name = shift;
	my $filename = shift;
	my $type = shift;
	my $location = shift;
	my $data = shift;

	my $sth = $self->query('set_new_file');
	$self->delete_file($name, $type);
	$sth->execute($name, $filename, $type, $location, $data);
	
}

sub delete_file
{
	my $self = shift;
	my $name = shift;
	my $type = shift;

	my $sth = $self->query('delete_file');
	$sth->execute($name, $type);

	return 1;
}
## Assembly
                                                                                                                                                
sub total_contigs
{
	my $self = shift;
        my $sth = $self->query('total_contigs');
        $sth->execute;
        return $sth->fetchrow_hashref->{'num_contigs'};
}
                                                                                                                                                
sub total_contig_bases
{
	my $self = shift;
        my $sth = $self->query('total_contig_bases');
        $sth->execute();
        return $sth->fetchrow_hashref->{bases};
}

sub total_supercontigs
{
	my $self = shift;
        my $sth = $self->query('all_supercontigs');
        $sth->execute;
        return $sth->rows;
}

sub total_contig_bases_in_supercontig_between
{
	my $self = shift;
        my $min_bases = shift;
        my $max_bases = shift;
        my $sth = $self->query('get_sum_ontigs_size_in_supercontig_between');
        $sth->execute($min_bases, $max_bases);
        return $sth->fetchrow_hashref->{contig_sum};
}
                                                                                                                                                
sub total_contigs_in_supercontigs_between
{
	my $self = shift;
        my $min_bases = shift;
        my $max_bases = shift;
        my $sth = $self->query('get_num_contigs_in_supercontig_between');
        $sth->execute($min_bases, $max_bases);
        return $sth->fetchrow_hashref->{num_contigs};
}


sub num_contigs_in_supercontig
{
	my $self = shift;
        my $supercontig_id = shift;
        my $sth = $self->query('num_contigs_in_supercontig');
        $sth->execute($supercontig_id);
        return $sth->fetchrow_hashref->{num_contigs};
}
                                                                                                                                                
sub num_contig_bases_in_supercontig
{
	my $self = shift;
        my $super_id = shift;
        my $sth = $self->query('num_contig_bases_in_supercontig');
        $sth->execute($super_id);
        return $sth->fetchrow_hashref->{num_bases};
                                                                                                                                                
}
                                                                                                                                                
sub modified_supercontig_length
{
	my $self = shift;
        my $super_id = shift;
        my $sth = $self->query('modified_supercontig_length');
        $sth->execute($super_id);
        return $sth->fetchrow_hashref->{modified_bases_in_super};
}
                                                                                                                                                
sub num_bases_as_gaps_in_supercontig
{
	my $self = shift;
        my $super_id = shift;
        return ($self->modified_supercontig_length($super_id) - $self->num_contig_bases_in_supercontig($super_id));
}



sub translate_nt
{
	my $self = shift;
        my $sequence = shift;
        my $seq = Bio::Seq->new( -seq=>$sequence );
        return $seq->translate->seq;
}

sub reverse_complement
{
	my $self = shift;
        my $sequence = shift;
        my $seq = Bio::Seq->new( -seq=>$sequence );
        return $seq->revcom->seq;
	
}


sub get_locations_from_contigs
{
	my $self = shift;
	my $seq = shift;
	
	my $dbh = $self->dbh;
	my $return_array = ();
	
	$seq =~ s/[^ATGC]//ig;
	my $seq_length = length($seq);
	
	my $contigh = $dbh->prepare("select contig_number, length(bases) as contig_length from contigs order by contig_number");
	
	my $sth = $dbh->prepare("select contig_number, locate(upper(?), upper(bases), ?) as seq_position from contigs");
	my $contig_find_h = $dbh->prepare("select contig_number, locate(upper(?), upper(bases), ?) as seq_position from contigs where contig_number = ?");
	
	my $continue = 1;
	
	my $rc_seq = $self->reverse_complement($seq);
	
	$contigh->execute();
	while(my $contig = $contigh->fetchrow_hashref)
	{
		my $start = 1;
		
		# Find the forward sequence
		my $dir = "+";

		while($start > 0)
		{
			$contig_find_h->execute($seq, $start, $contig->{contig_number});
			my $found_row = $contig_find_h->fetchrow_hashref;
			if($found_row->{seq_position} > 0)
			{
				my $match;
				$start = $found_row->{seq_position} + 1;
				$match->{contig} = $contig->{contig_number};
				$match->{direction} = $dir;
				$match->{start} = $found_row->{seq_position};
				$match->{stop} = $found_row->{seq_position} + $seq_length - 1;
				push(@$return_array, $match);
				
			} else
			{
				$start = 0;
			}
		}
		
		# Now search for the reverse of the sequence
		$dir = "-";
		$start = 1;
		while($start > 0)
		{
			$contig_find_h->execute($rc_seq, $start, $contig->{contig_number});
			my $found_row = $contig_find_h->fetchrow_hashref;
			if($found_row->{seq_position} > 0)
			{
				my $match;
				$start = $found_row->{seq_position} + 1;
				$match->{contig} = $contig->{contig_number};
				$match->{direction} = $dir;
				$match->{start} = $found_row->{seq_position};
				$match->{stop} = $found_row->{seq_position} + $seq_length - 1;
				push(@$return_array, $match);
			} else
			{
				$start = 0;
			}
		}
		
	}
	
	return $return_array;
	
}
sub get_contig_from_supercontig_coord
{
	my $self = shift;
	my $supercontig_id = shift;
	my $coord = shift;

	my $dbh = $self->dbh;
	my $sth = $dbh->prepare("select contig_number from links where super_id = ? AND modified_contig_start_base < ? AND (modified_contig_start_base+contig_length) > ?");

	my ($striped) = $supercontig_id =~ /(\d+)/;
	$sth->execute($striped, $coord, $coord);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{contig_number};
	} else
	{
		return 0;
	}
	
}

sub get_contig_coords_from_supercontig
{
	my $self = shift;
	my $supercontig_id = shift;
	my $coord = shift;

	my $dbh = $self->dbh;
	my $sth = $dbh->prepare("select contig_number, modified_contig_start_base  from links where super_id = ? AND modified_contig_start_base < ? AND (modified_contig_start_base+contig_length) > ?");
	my ($striped) = $supercontig_id =~ /(\d+)/;
	$sth->execute($striped, $coord, $coord);
	if($sth->rows > 0)
	{
		return ($coord - $sth->fetchrow_hashref->{modified_contig_start_base} + 1) ;
	} else
	{
		return 0;
	}
}


sub contig_info
{
	my $self = shift;
	my $contig = shift;

	my $sth = $self->query('contig_info');
	$sth->execute($contig);

	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref;
	} else
	{
		# Check if this just needs contig_ striped from if
		my ($striped) = $contig =~ /(\d+)/;
		$sth->execute($striped);
		if($sth->rows > 0)
		{
			return $sth->fetchrow_hashref;
		} else
		{
			return undef;
		}
	}

}

sub get_contig_table
{
	my $self = shift;
	my $contig = shift;

	my $row = $self->contig_info($contig);
	if(!$row)
	{
		return 'No information available';
	}
	my $ret_val = '';
	$ret_val = table( { -border=>'1', -width=>'300'},
		TR(
			th( "Contig"), td($row->{contig_number})
		),
		TR(
			th("Super Contig"), td($row->{super_id})
		),
		TR(
			th("Contig Length"), td($row->{contig_length})
		),
		TR(
			th("Ordinal Number"), td($row->{ordinal_number})
		),
		TR(
			th("Supercontig Length"), td($row->{bases_in_super})
		),
		TR(
			th("Supercontig Length<br>(with 100bp minimum gap)"), td($row->{modified_bases_in_super})
		),
		TR(
			th("Contigs in This Supercontig"), td($row->{contigs_in_super})
		),
		TR(
			th("Gap Before Contig"), td($row->{gap_before_contig})
		),
		TR(
			th("Gap After Contig"), td($row->{gap_after_contig})
		),
		TR(
			th("Start Position in Supercontig<br>(with 100bp minimum gap)"), td($row->{modified_contig_start_base})
		)
	);

	return $ret_val;
		
}


sub get_contig_links_table
{
	my $self = shift;
	my $contig = shift;

        my $sth = $self->query('contig_links');
        $sth->execute($contig);

	if($sth->rows < 1)
	{
		return 'No Linking Information Found for Contig ' . $contig;
	}
	my $ret_val = '';
	$ret_val .= '<table border=1><tr><th>Supercontig</th><th>Contig</th><th>Paired Links</th></tr>' . "\n";

	while(my $row = $sth->fetchrow_hashref)
	{
		my $contig_info = $self->contig_info($row->{read_pair_contig_number});
		my $supercontig = $contig_info->{super_id};
		$ret_val .= '<tr><td>' . $self->gbrowse_supercontig_link($supercontig) . '</td><td>' .
				$self->contig_link($row->{read_pair_contig_number}) . '</td><td>' . 
				$self->contig_linking_reads_link($contig, $row->{read_pair_contig_number}, $row->{read_count}) . "</td></tr>\n";
	}
	$ret_val .= '</table>';

} 

sub get_contig_linking_reads_table
{
	my $self = shift;
	my $contig_one = shift;
	my $contig_two = shift;

	my $sth = $self->query('contig_linking_reads');

	$sth->execute($contig_one, $contig_two);

	if($sth->rows > 0)
	{
		my $ret_val = '';
		$ret_val .= '<table border=1 width=350><tr><th>Read Name</th><th>Orientation</th><th>Pair Name</th></tr>';
		while(my $row = $sth->fetchrow_hashref)
		{
			$ret_val .= '<tr><td>' . $self->read_link($row->{read_name}) . '</td><td>' . $row->{orientation} . '</td><td>' . $self->read_link($row->{read_pair_name}) . '</td></tr>' . "\n";
		}

		$ret_val .= '</table>';
		return $ret_val;
	} else
	{
		return 'No Linking Reads Between These Contigs';
	}
}

sub contig_reads
{
	my $self = shift;
	my $contig_name = shift;

	my $sth = $self->query('contig_reads');
	$sth->execute($contig_name);
	
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		return $row;
	} else
	{
		return undef;
	}
}
sub read_info
{
	my $self = shift;
	my $read_name = shift;

	my $sth = $self->query('read_information');
	$sth->execute($read_name);
	
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		return $row;
	} else
	{
		return undef;
	}
}

sub get_read_table
{
	my $self = shift;
	my $read_name = shift;
	my $ret_val = '';

	my $read = $self->read_info($read_name);
	if(!$read)
	{
		return undef;
	}
	my $super_id;
	my $partner_super_id;
	my $contig_link;
	my $supercontig_link;
	if($read->{contig_number})
	{
		($super_id, undef, undef) = $self->get_supercontig_coords_from_contig($read->{contig_number});
	}
	if($read->{read_pair_contig_number})
	{
		($partner_super_id, undef, undef) = $self->get_supercontig_coords_from_contig($read->{read_pair_contig_number});
	}

	$ret_val = table( { -border=>'1', -width=>'100%'}, 
				TR(
					th( "Read Name"), td($read->{read_name})
				),
				TR(
					th('Sequencing Center'), td($read->{center_name})
				),
				TR(
					th('Template Name'), td($read->{template_id})
				),
				TR(
					th('Plate'), td($read->{plate_id})
				),
				TR(
					th('Well'), td($read->{well_id})
				),
				TR(
					th('Library'), td($read->{library_id})
				),
				TR(
					th('Trace End'), td($read->{trace_end})
				),
				TR(
					th('Trace Direction'), td($read->{trace_direction})
				),
				TR(
					th('Status'), td($read->{status})
				),
				TR(
					th('Read Status'), td($read->{read_status})
				),
				TR(
					th('Untrimmed Length'), td($read->{read_len_untrim})
				),
				TR(
					th('Trimmed Length'), td($read->{read_len_trim})
				),
				TR(
					th('First Base of Trim'), td($read->{first_base_of_trim})
				),
				TR(
					th('Contig'), td($self->gbrowse_contig_link($read->{contig_number}))
				),
				TR(
					th('Supercontig'), td($self->gbrowse_supercontig_link($super_id))
				),
				TR(
					th('Orientation'), td($read->{orientation})
				),
				TR(
					th('Start Location in Contig'), td($read->{trim_read_in_contig_start})
				),
				TR(
					th('Stop Location in Contig'), td($read->{trim_read_in_contig_stop})
				),
				TR(
					th('Read Mate Name'), td($self->read_link($read->{read_pair_name}))
				),
				TR(
					th('Read Mate Contig'), td($read->{read_pair_contig_number})
				),
				TR(
					th('Read Mate Supercontig'), td($self->gbrowse_supercontig_link($partner_super_id))
				),
				#TR(
				#	th('Read Mate Supercontig'), td($partner_super_id)
				#),
				TR(
					th('Observed Insert Size'), td($read->{observed_insert_size})
				),
				TR(
					th('Given Insert Size'), td($read->{given_insert_size})
				),
				TR(
					th('Given Insert StdDev'), td($read->{given_insert_std_dev})
				),
				TR(
					th('Observed Insert StdDev'), td($read->{observed_inserted_deviation})
				)
			);
	return $ret_val;
	
}

sub get_read_partner
{
	my $self = shift;
	my $read_name = shift;

	my $read = $self->read_info($read_name);

	# Check by the reads assembly table for the pair
	if($read->{read_pair_name})
	{
		return $read->{read_pair_name};
	}

	# Next check by using the template value
	my $sth = $self->query('read_pair_template');
	if($read->{template_id} ne '' && $read->{template_id} != undef)
	{
		$sth->execute($read->{read_name}, $read->{template_id});
		if($sth->rows > 0)
		{
			my $row = $sth->fetchrow_hashref;
			return $row->{read_name};
		}
	}
	return undef;
}

sub get_read_sequence
{
	my $self = shift;
	my $read_name = shift;
	
	my $sth = $self->query('read_sequence');
	$sth->execute($read_name);
	if(my $row = $sth->fetchrow_hashref)
	{
		return $row->{bases};
	} else
	{
		return undef;
	}
}

sub get_read_sequence_trim
{
        my $self = shift;
        my $read_name = shift;
                                                                                                                            
        my $sth = $self->query('read_sequence_trim');
        $sth->execute($read_name);
        if(my $row = $sth->fetchrow_hashref)
        {
                return $row->{bases};
        } else
        {
                return undef;
        }
}

sub get_read_qual_array
{
	my $self = shift;
	my $read_name = shift;

	my $sth = $self->query('get_read_qual');
	$sth->execute($read_name);
	
	my @quals;
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		(@quals) = $row->{quality} =~ /\d+/g;
	}
	return \@quals;
}

sub get_read_qual_sequence
{
	my $self = shift;
	my $read_name = shift;

	my $sth = $self->query('get_read_qual');
	$sth->execute($read_name);
	
	my @quals;
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		my $ret_string;
		(@quals) = $row->{quality} =~ /\d+/g;
		my $num = 1;
		foreach my $q (@quals)
		{
			$ret_string .= "$q";
			$num++;
			if($num == 26)
			{
				$ret_string .= "\n";
				$num = 1;
			} else
			{
				$ret_string .= " ";
			}
		}
		return $ret_string;
	} else
	{
		return "";
	}
	
}

sub get_contig_qual_sequence
{
	my $self = shift;
	my $contig_number = shift;

	my $sth = $self->query('get_contig_qual');
	$sth->execute($contig_number);
	
	my @quals;
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		my $ret_string;
		(@quals) = $row->{quality} =~ /\d+/g;
		my $num = 1;
		foreach my $q (@quals)
		{
			$ret_string .= "$q";
			$num++;
			if($num == 26)
			{
				$ret_string .= "\n";
				$num = 1;
			} else
			{
				$ret_string .= " ";
			}
		}
		return $ret_string;
	} else
	{
		return "";
	}
	
}




sub get_taxid_from_gi
{
	my $self = shift;
	my $gi = shift;
	my $sth = $self->query('get_taxid_gi');
	$sth->execute($gi);
	
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{taxid};
	} else
	{
		return undef;
	}


}

sub get_genbank_seq
{
	my $self = shift;
        my $gi = shift;
	my $db = shift;
	if(!defined($db))
	{
		$db = 'nr';
	}
        `/bioware/blast/fastacmd -d $db -s $gi > /tmp/$gi`;
        my $seqio = Bio::SeqIO->new(-file =>"/tmp/$gi",-format=>"fasta");
	
        my $seq = $seqio->next_seq();
	if($seq)
	{
	#        my $retseq =  Bio::Seq->new( -display_id=>'gi|'. $gi , -seq=>$seq->seq);
	        `rm -f /tmp/$gi`;
	 #       return $retseq;
		return $seq;
	} else
	{
	        `rm -f /tmp/$gi`;
		return undef;
	}

}

sub create_alignment_string
{
	my $self = shift;
        my $aln = shift;
        my $format = shift;

        my $str;
        my $out = IO::String->new(\$str);
        my $ioout = Bio::AlignIO->new(-format=> $format, -fh => $out );
        $ioout->write_aln($aln);
        return $str;
}

sub get_alignment_links
{
	my $self = shift;
	my $idname = shift;

	my $sth = $self->query('get_alignment_descriptions');
	$sth->execute($idname);
	my $ret_str = '';
	if($sth->rows > 0)
	{
		while(my $row = $sth->fetchrow_hashref)
		{
			$ret_str .= $self->stored_multiple_alignment_link($row->{id}, $row->{description}, $idname) . "<br>";	
		}
		return $ret_str;
	} else
	{
		return 'None';
	}
}

sub get_tree_links
{
        my $self = shift;
        my $idname = shift;

        my $sth = $self->query('get_tree_descriptions');
        $sth->execute($idname);
        my $ret_str = '';
        if($sth->rows > 0)
        {
                while(my $row = $sth->fetchrow_hashref)
                {
                        $ret_str .= $self->tree_page_link($row->{id}, $row->{description}, $row->{type}) . "<br>";
                }
                return $ret_str;
        } else
        {
                return 'None';
        }
}

sub get_stored_tree_string
{
	my $self = shift;
	my $id = shift;

	my $sth = $self->query('get_stored_tree');
	$sth->execute($id);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{tree};
	} else
	{
		return undef;
	}
}

sub get_stored_tree_id_from_ma_id
{
	my $self = shift;
	my $ma_id = shift;

	my $sth = $self->query('get_stored_tree_from_ma_id');
	$sth->execute($ma_id);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{id};
	} else
	{
		return undef;
	}
}

sub remove_duplicate_seq
{
	my $self = shift;
        my $seq_array = shift;
        my %seq_hash;
        foreach my $seq (@{$seq_array})
        {
                $seq_hash{$seq->display_id} = $seq;
        }
        my $ret_array;
        while(my ($key, $val) = each %seq_hash)
        {
                push(@{$ret_array}, $val);
        }
        return $ret_array;

}


sub find_seq_in_contigs
{
	my $self = shift;
	my $seq = shift;

	$seq = uc($seq);

	my $rc_seq = reverse($seq);
	$rc_seq =~ tr/CATG/GTAC/;

	

}


sub compare_prss
{
	my $self = shift;
        my $seq1 = shift;
        my $seq2 = shift;
        my $iterations = shift;;
        my $num_entries = shift;

        my $seq1_name = int(rand(100000));
        my $seq2_name = int(rand(100000));

        open(FASTA1, ">", "/tmp/.$seq1_name.prss");
        open(FASTA2, ">", "/tmp/.$seq2_name.prss");

        print FASTA1 ">$seq1_name\n";
        print FASTA1 $seq1->seq();
        print FASTA2 ">$seq2_name\n";
        print FASTA2 $seq2->seq();
        close(FASTA1);
        close(FASTA2);

        my $result = `prss34 -s BL62 -f 11 /tmp/.$seq1_name.prss /tmp/.$seq2_name.prss $iterations`;

        my ($eval) = $result =~ /unshuffled.+\<(.+)/;
        $eval =~ s/ //gi;

        system('rm -f /tmp/.' . $seq1_name . '.prss');
        system('rm -f /tmp/.' . $seq2_name . '.prss');

        return ($eval * ($num_entries+$iterations));

}

sub get_stored_alignment
{
	my $self = shift;
	my $id = shift;
	
	my $sth = $self->query('get_stored_alignment');
	$sth->execute($id);
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		my $string = $row->{ma};
		my $type = $row->{type};
		open(ALIGN, ">", "/tmp/$id.nxs");
		print ALIGN $string;
		close(ALIGN);
		my $in  = Bio::AlignIO->new(-file =>"/tmp/$id.nxs", -format=>$type);
		my $align = $in->next_aln();
		return $align;
	} else
	{
		return undef;
	}
}

sub get_stored_alignment_annotation
{
	my $self = shift;
	my $id = shift;
	my $ma_id;
	my $annotation_str;
	
	my $sth = $self->query('get_stored_alignment');
	$sth->execute($id);
	if($sth->rows > 0)
	{
		my $row = $sth->fetchrow_hashref;
		$ma_id = $row->{id};
	} else {
		return "";
	}

	$sth = $self->query('get_stored_alignment_annotation');
	$sth->execute($ma_id);
	while (my $this_row = $sth->fetchrow_hashref)
	{
		$annotation_str .= $this_row->{annotation} . "\n";
	}
	return $annotation_str;
}


sub get_taxon_name_from_taxid
{
	my $self = shift;
	my $taxid = shift;
	my $sth = $self->query('get_name_from_taxid');
	$sth->execute($taxid);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{name};
	} else
	{
		return undef;
	}
}


sub get_sequence_type_name
{
	my $self = shift;
	my $id = shift;

	my $sth = $self->query('get_sequence_type_name');
	$sth->execute($id);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{type};
	} else
	{
		return 0;
	}
}

sub get_sequence_type_id
{
	my $self = shift;
	my $name = shift;

	my $sth = $self->query('get_sequence_type_id');
	$sth->execute($name);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{id};
	} else
	{
		return 0;
	}
}

sub get_db_name
{
	my $self = shift;
	my $id = shift;

	my $sth = $self->query('get_db_name');
	$sth->execute($id);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{name};
	} else
	{
		return 0;
	}
}

sub get_db_id
{
	my $self = shift;
	my $name = shift;

	my $sth = $self->query('get_db_id');
	$sth->execute($name);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{id};
	} else
	{
		return 0;
	}
}

sub get_algorithm_name
{
	my $self = shift;
	my $id = shift;

	my $sth = $self->query('get_algorithm_name');
	$sth->execute($id);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{name};
	} else
	{
		return 0;
	}
}

sub get_algorithm_id
{
	my $self = shift;
	my $name = shift;

	my $sth = $self->query('get_algorithm_id');
	$sth->execute($name);
	if($sth->rows > 0)
	{
		return $sth->fetchrow_hashref->{id};
	} else
	{
		return 0;
	}
}

sub wrap 
{
	my $self = shift;
	my $text = shift;
	my $wrap_num = shift;
	my $ret_text = join("\n", split /(.{80})/, $text);
	$ret_text =~ s/\n\n/\n/g;
	return $ret_text;
}

sub percent_it {
	my $self = shift;
        my $num = shift;
        return $self->commify((sprintf("%.2f", $num) . "%"));
}

sub trunc_it {
	my $self = shift;
	my $num = shift;
        return $self->commify((sprintf("%.2f", $num)));
}

sub commify {
	my $self = shift;
	my $text = reverse $_[0];
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}
sub log10 {
	my $self = shift;
	my $n = shift;
	if($n == 0)
	{
		return 0;
	}
	return log($n)/log(10);
}

sub get_median
{
	my $self = shift;
	my $input_array = shift;

	my @sorted = sort{$a <=> $b} @$input_array;
	my $mid_val = int( (scalar @sorted) / 2) - 1;
	return $input_array->[$mid_val];
}

sub get_min
{
	my $self = shift;
	my (@nums) = @_;

	my $min;
	foreach my $num (@nums)
	{
		if(!defined($min))
		{
			$min = $num;
		} elsif( $min > $num )
		{
			$min = $num;
		}
	}

	return $min;
	
}
sub get_max
{
	my $self = shift;
	my (@nums) = @_;

	my $max;
	foreach my $num (@nums)
	{
		if(!defined($max))
		{
			$max = $num;
		} elsif( $max < $num )
		{
			$max = $num;
		}
	}

	return $max;
	
}

sub l50
{
	my $self = shift;
        my $list = shift;
        my @array = sort {$a <=> $b} @{$list};
        # First find the sum/2
        my $tot = 0;
        my $l50score = 0;
                                                                                                                                                
        foreach (@array)
        {
                $tot += $_;
        }
        $tot = $tot/2;
        # Now go through the array again, and when we reach tot/2, return the value
        my $retval = 0;
        foreach(@array)
        {
                $retval += $_;
                if($retval >= $tot)
                {
                        return $_;
                }
        }
        return 0;
                                                                                                                                                
}

sub db_subselect
{
	my $self = shift;
	my $subselect = shift;
	
	my $dbh = $self->dbh;

	my $query = $dbh->prepare($subselect);
	my $return_query = '';

	if($query)
	{
		$query->execute();
		if($query->rows > 0)
		{
			my $first = 1;
			while(my $row = $query->fetchrow_arrayref)
			{
				if($first)
				{
					$return_query = "'" . $row->[0] . "'";
					$first = 0;
				} else
				{
					$return_query .= ", '" . $row->[0] . "'";
				}
			}
		} else
		{
			return 'NULL';
		}
		
		return $return_query;
	} else
	{
		return 0;
	}
}

sub create_overlib
{
	my $self = shift;
	my $display_text = shift;
	my $over_text = shift;
	my $href = shift;
	my $options = shift;
	if(!$href)
	{
		$href = 'javascript:void(0)';
	}
	if(!$options)
	{
	} else
	{
		$options = $options . ', ' 
	}

	$over_text =~  s/\&/\&amp\;/gi;
	$over_text =~ s/\"/\&quot\;/gi;
	my $return_val = '<a href="' . $href . ';" onmouseover="return overlib(\'' . $over_text . '\', ' . $options . 'MOUSEOFF, WIDTH, 400);" onmouseout="return nd();">' . $display_text . "</a>";
	return $return_val;
}


# Preloaded methods go here.


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mbl - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Mbl;
  blah blah blah

=head1 ABSTRACT

  This should be the abstract for Mbl.
  The abstract is used when making PPD (Perl Package Description) files.
  If you don't want an ABSTRACT you should also edit Makefile.PL to
  remove the ABSTRACT_FROM option.

=head1 DESCRIPTION

Stub documentation for Mbl, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.22 with options

  -ACXn
	Mbl

=back



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

root, E<lt>root@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
