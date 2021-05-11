#!/usr/bin/perl


use strict;
use Mbl;
 
 
my $mbl = Mbl::new(undef, $ARGV[0]);
my $dbh = $mbl->dbh;


my $shared_dbh = $mbl->shared_dbh;

my $update_sql = 1;

# Things that need to change
my $old_file_location_1 = '/var/www/html/gbrowse/';
my $new_file_location_1 = '/xraid/bioware/gmod/mblweb-gmod/html/';
my $old_file_location_2 = '/var/www/html/';
my $new_file_location_2 = '/xraid/bioware/gmod/mblweb-gmod/html/';



my $update_file_location_q = "update files set location = ? where id = ?";
my $db_list_h = $shared_dbh->prepare("select id, database_name, project_name, access_type from gmodweb_databases order by database_name");

my $add_template_q = "insert into templates (template_file, page_name, id) VALUES (?, ?, ?)";

$db_list_h->execute();



while(my $dbrow = $db_list_h->fetchrow_hashref)
{
	print $dbrow->{database_name} . "\n";

	# Connect to database

	my $cur_mbl = Mbl::new(undef, $dbrow->{database_name});
	my $cur_dbh = $cur_mbl->dbh();
	if(!defined($cur_dbh))
	{
		print " Not Found\n";
		next;
	}

	# Update files table

	my $file_h = $cur_dbh->prepare("select id, name, location from files order by name");

	$file_h->execute();

	my $update_file_location_h = $cur_dbh->prepare($update_file_location_q);

	while(my $file = $file_h->fetchrow_hashref)
	{
		my $loc = $file->{location};
		if($loc =~ /$old_file_location_1/)
		{
			$loc =~ s/$old_file_location_1/$new_file_location_1/;
			print " " . $file->{location} . " -> $loc\n";
			if($update_sql)
			{
				$update_file_location_h->execute($loc, $file->{id});
			}
		} elsif( $loc =~ /$old_file_location_2/)
		{
			$loc =~ s/$old_file_location_2/$new_file_location_2/;
			print " " . $file->{location} . " -> $loc\n";
			if($update_sql)
			{
				$update_file_location_h->execute($loc, $file->{id});
			}
		}
		
	}

	# Check that specific templates exist, and if not, add them
	if(check_page_exists($dbrow->{database_name}, 'admin_page'))
	{
		# Do Nothing
		print " admin_page Exists\n";
	} else
	{
		print " Adding template admin_page\n";
		my $add_template_h = $cur_dbh->prepare($add_template_q);
		if($update_sql)
		{
			$add_template_h->execute('admin_page.tt', 'admin_page', undef);
		}
	}

	# Change privilieges
	my $gbrowse_db_name = $dbrow->{database_name} . "screads";
	my $update_q = "grant select on $gbrowse_db_name" . '.* to gbrowse@\'%\' identified by \'ropassword123\'';
	if($update_sql)
	{
		$cur_dbh->do($update_q);
	}


	# Add admin user and admin rights

	my $admin_check_h = $cur_dbh->prepare("select id, user_name from user where lower(user_name) = 'admin'");
	$admin_check_h->execute();
	if($admin_check_h->rows == 0)
	{
		print " Admin user does not exist, creating\n";
		my $admin_ins = $cur_dbh->prepare("insert into user (id, user_name, first_name, last_name, active_fg, password, email, institution) VALUES (NULL, 'Admin', 'Site', 'Administrator', 'Y', '', 'gmod\@lists.mbl.edu', 'Marine Biological Laboratory') ");

		if($update_sql)
		{
			$admin_ins->execute();
		}
	} else
	{
		print " Admin user exists\n";
	}

	# Now get the admin user_id
	my $get_admin_id_h = $cur_dbh->prepare("select id from user where lower(user_name) = 'admin'");
	$get_admin_id_h->execute();
	my $admin_row;
	if($admin_row = $get_admin_id_h->fetchrow_hashref)
	{
		my $admin_id = $admin_row->{id};
		# Now check for admin rights
		my $check_admin_rights_h = $cur_dbh->prepare("select id, userid from user_rights where lower(rights) = 'annotation admin' AND lower(type) = 'annotation' AND userid = ?");
		$check_admin_rights_h->execute($admin_id);
		if($check_admin_rights_h->rows == 0)
		{
			print " Adding Administrator Rights\n";
			my $ins_admin_rights_h = $cur_dbh->prepare("insert into user_rights (id, userid, rights, type) VALUES (NULL, ?, 'Annotation Admin', 'annotation')");
			if($update_sql)
			{
				$ins_admin_rights_h->execute($admin_id);
			}
		} else
		{
			print " Administrator Rights already exist\n";
		}

	} else
	{
		print " Admin user does not exist so can not create admin rights\n";
	}

	# Update html_site_cgi to the correct location

	my $sitecgi_h = $cur_dbh->prepare("update html set value = '/perl/site' where template = 'default' AND variable = 'html_site_cgi'");
	$sitecgi_h->execute();

}



sub check_page_exists
{
	my $db_name = shift;
	my $page_name = shift;

	my $mbla =  Mbl::new(undef, $db_name);
	my $dbha = $mbla->dbh();
	my $checkh = $dbha->prepare("select page_name from templates where page_name = ?");
	$checkh->execute($page_name);

	if($checkh->rows > 0)
	{
		return 1;
	} else
	{
		return 0;
	}
}
