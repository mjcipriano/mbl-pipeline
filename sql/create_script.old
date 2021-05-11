-- Server version	4.1.7-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT, CHARACTER_SET_CLIENT=utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;

--
-- Table structure for table `action_list`
--
-- DESCRIPTION:
--  This table will store read names and various actions that can be performed on them
--  Such as 
--  action_list table is a legacy table and is no longer used
DROP TABLE IF EXISTS `action_list`;
CREATE TABLE `action_list` (
  `read_name` varchar(20) default NULL,
  `action` varchar(20) default NULL,
  UNIQUE KEY `action_list_read_action_unq_idx` (`read_name`,`action`),
  KEY `action_list_action_read_idx` (`action`,`read_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `algorithms`
--
-- DESCRIPTION
--  This table lists the various searching algorithms that are available
--  such as blastp, tblastx, pfam, etc.
DROP TABLE IF EXISTS `algorithms`;
CREATE TABLE `algorithms` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(20) default NULL,
  PRIMARY KEY  (`id`),
  KEY `algorithms_name_id` (`name`,`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `annotation`
--
-- DESCRIPTON
--  This table lists the annotations on a open reading frame.
--   id - Primary key
--   userid -> user.id
--   orfid -> orfs.orfid
--   update_dt (timestamp when the record gets updated)
--    annotation (free text annotation)
--   notes (free text notes)
--   delete_fg (Y or N, used to flag a annotation for deletion)
--   blessed_fg (Y or N, used to bless an annotation as a true annotation)
--   qualifier (a GO term, one of  NOT, contributes_to, or NULL
--   with_from (a GO term, format DB:ACCESSION | DB:ACCESSION | ...)
--   aspect (one of  P (biological process), F (molecular function) or C (cellular component) )
--   object_type (one of gene, transcript, protein, protein_structure, complex)
--   evidence_code -> evidence_codes.id
--   private_fg (Y or N, if flagged Y, this will not show up on the public database except for that user)

DROP TABLE IF EXISTS `annotation`;
CREATE TABLE `annotation` (
  `id` int(11) NOT NULL auto_increment,
  `userid` int(11) default NULL,
  `orfid` int(11) default NULL,
  `update_dt` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `annotation` varchar(255) default NULL,
  `notes` text,
  `delete_fg` char(1) default NULL,
  `blessed_fg` char(1) default NULL,
  `qualifier` varchar(50) default NULL,
  `with_from` varchar(255) default NULL,
  `aspect` char(1) default NULL,
  `object_type` varchar(30) default NULL,
  `evidence_code` int(11) default NULL,
  `private_fg` char(1) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `annotation_unique_idx` (`userid`,`orfid`,`annotation`,`notes`(100)),
  KEY `ofid_idx` (`orfid`),
  KEY `annotation_idx` (`annotation`),
  KEY `update_dt_idx` (`update_dt`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `blast_report_full`
--
-- DESCRIPTION
--  This table will store a full sequence search report.  Individual records are stored
--  in the blast_results table.
--   idname (definition varies depending on sequence_type)
--   report (the full text of the report)
--   sequence_type_id -> sequence_types.id
--   db_id -> db.id
--   algorithm_id -> algorithms.id

DROP TABLE IF EXISTS `blast_report_full`;
CREATE TABLE `blast_report_full` (
  `idname` varchar(255) default NULL,
  `report` longtext,
  `sequence_type_id` int(11) default NULL,
  `db_id` int(11) default NULL,
  `algorithm_id` int(11) default NULL,
  KEY `blast_report_full_type_id_idx` (`sequence_type_id`,`idname`),
  KEY `blast_report_full_db_id_idx` (`db_id`),
  KEY `blast_report_full_all` (`idname`,`sequence_type_id`,`db_id`,`algorithm_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=4294967295 AVG_ROW_LENGTH=500;

--
-- Table structure for table `blast_results`
--
-- DESCRIPTION
--  This table stores the individual sequence search results. The term blast_results is a legacy term
--  and this table stores more then blast results currently.
--   idname (the definition of this varies depending on sequence_type.  For ORFS, it is the orfid)
--   score (the score of the result if given)
--   hit_start (the start of the result on the hit sequence)
--   hit_end  (the end of the result on the hit sequence)
--   hit_name (the free text name as would be returned by $hit->name from a bioperl hit object)
--   accession_number (the accession number of the hit if known)
--   description (A free text description of the result)
--   algorithm -> algorithms.id
--   db -> db.id
--   gaps (the number of gaps present in the hit)
--   frac_identical (the fraction of identical residues, a number between 0 and 1)
--   frac_conserved (the fraction of conserved residues, a number between 0 and 1)
--   query_string (the text of the query portion of the alignment)
--   hit_string (the text of the hit portion of the alignment)
--   homology_string (the text which shows how a base/aa pairs in the alignment)
--   hsp_rank (the ranking of this particular hsp in the result)
--   evalue (the expectation value if appropriate or known)
--   hsp_strand (the strand that this hsp is on 1, 0, or -1)
--   hsp_frame (the frame that this hsp is on, one of 0, 1, 2)
--   sequence_type_id -> sequence_types.id
--   primary_id (this field has different meanings based on the search type. It can be the GO id sometimes)
--   query_start (the start position on the query sequence of the match)
--   query_end (the end position on the query sequence of the match)
--   hit_rank (the rank of this hit within the whole blast report)
--   id (a auto incrementing unique value)
--   gi (the gi number of the hit sequence)

DROP TABLE IF EXISTS `blast_results`;
CREATE TABLE `blast_results` (
  `idname` varchar(255) default NULL,
  `score` float default NULL,
  `hit_start` int(11) default NULL,
  `hit_end` int(11) default NULL,
  `hit_name` varchar(255) default NULL,
  `accession_number` varchar(20) default NULL,
  `description` varchar(255) default NULL,
  `algorithm` int(11) default NULL,
  `db` int(11) default NULL,
  `gaps` int(11) default NULL,
  `frac_identical` float default NULL,
  `frac_conserved` float default NULL,
  `query_string` text,
  `hit_string` text,
  `homology_string` text,
  `hsp_rank` int(11) default NULL,
  `evalue` double default NULL,
  `hsp_strand` int(11) default NULL,
  `hsp_frame` int(11) default NULL,
  `sequence_type_id` int(11) default NULL,
  `primary_id` varchar(20) default NULL,
  `query_start` int(11) default NULL,
  `query_end` int(11) default NULL,
  `hit_rank` int(11) default NULL,
  `id` int(11) NOT NULL auto_increment,
  `gi` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `blast_results_type_idx` (`sequence_type_id`),
  KEY `blast_results_all` (`idname`,`sequence_type_id`,`algorithm`,`db`),
  KEY `blast_results_desc_idx` (`description`),
  KEY `blast_results_hit_name_idx` (`hit_name`),
  KEY `blast_results_accession_idx` (`accession_number`),
  KEY `blast_results_gi_idx` (`gi`),
  KEY `blast_results_evalue` (`evalue`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=4294967295 AVG_ROW_LENGTH=500;

--
-- Table structure for table `contig_quality`
--
-- DESCRIPTION
--  The quality of a particular contig as a string of numbers with spaces in between each position
--   contig_number (the name of the contig (ex contig_33))
--   quality (a string of numbers with no newline. Each base is represented by a number with a space after it)

DROP TABLE IF EXISTS `contig_quality`;
CREATE TABLE `contig_quality` (
  `contig_number` varchar(255) NOT NULL default '',
  `quality` longtext,
  PRIMARY KEY  (`contig_number`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `contigs`
--
-- DESCRIPTION
--  The contig sequence in text form
--   contig_number  (the name of the contig (ex contig_33))
--   bases (the nucleotide bases of the contig with no newline chars and no spaces)

DROP TABLE IF EXISTS `contigs`;
CREATE TABLE `contigs` (
  `contig_number` varchar(255) default NULL,
  `bases` longtext,
  PRIMARY KEY  (`contig_number`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `current_phlyo`
--
-- DESCRIPTION
--  This table is used for the phylo pipeline to store the current running phylo
--  processes.
--  idname (usualy the orfid)
--  sequence_type_id -> sequence_types.id

DROP TABLE IF EXISTS `current_phlyo`;
CREATE TABLE `current_phlyo` (
  `idname` varchar(30) default NULL,
  `sequence_type_id` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `current_search`
--
-- DESCRIPTION
--  This table is used in the sequence searching pipeline to 
--  track which sequences are currently being searched.
--   idname (definition varies depending on sequence_type)
--   sequence_type_id -> sequence_types.id
--   db_id -> db.id
--   algorithm_id -> algorithms.id

DROP TABLE IF EXISTS `current_search`;
CREATE TABLE `current_search` (
  `idname` varchar(30) default NULL,
  `sequence_type_id` int(11) default NULL,
  `db_id` int(11) default NULL,
  `algorithm_id` int(11) default NULL,
  UNIQUE KEY `idname` (`idname`,`sequence_type_id`,`db_id`,`algorithm_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `db`
--
-- DESCRIPTION
--  This table will store the different types of databases
--  that are used in sequence searching. (nr, nt, swissprot, etc)

DROP TABLE IF EXISTS `db`;
CREATE TABLE `db` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(20) default NULL,
  PRIMARY KEY  (`id`),
  KEY `db_name_id` (`name`,`id`),
  KEY `db_id_name` (`id`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `evidence_codes`
--
-- DESCRIPTION
--  This table stores the GO terms for evidence codes

DROP TABLE IF EXISTS `evidence_codes`;
CREATE TABLE `evidence_codes` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(5) default NULL,
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `files`
--
-- DESCRIPTION
--  This table is used by gmoddb to store either the location of a type of
--  file or the actual file data itself.
--   id (primary key)
--   name (the name of the file used in queries along with type)
--   data (the actual data of the file.  This can be null if a filename is being stored)
--   type (the type of file being stored)
--   location (the directory that the file is stored in or null if the data is stored in the table)
--   filename (the filename to save the file as on the host machine and the filename of the file in the location)

DROP TABLE IF EXISTS `files`;
CREATE TABLE `files` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(55) default NULL,
  `data` longblob,
  `type` varchar(55) default NULL,
  `location` varchar(255) default NULL,
  `filename` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `files_name_type` (`name`,`type`),
  KEY `files_type` (`type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `html`
--
-- DESCRIPTION
--  This table stores the actual html used in the particular parts of the template
--   template -> templates.page_name (the specific page or default that this variable is linked to)
--   variable (the variable id used in the template like [% VARIABLE1 %])
--   value (the text that gets replaced by the variable in the template)

DROP TABLE IF EXISTS `html`;
CREATE TABLE `html` (
  `template` varchar(20) default NULL,
  `variable` varchar(40) default NULL,
  `value` text,
  UNIQUE KEY `template` (`template`,`variable`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `links`
--
-- DESCRIPTION
--  This table will describe the links between contigs that create scaffolds/supercontigs
--   super_id (the id of the supercontig)
--   bases_in_super (the size of the supercontig with overlapping contigs allowed)
--   contigs_in_super (the number of contigs in this scaffold/supercontig
--   ordinal_number (the position of this contig within the scaffold)
--   gap_before_contig (the calculated gap before this contig within the scaffold)
--   gap_after_contig (the calculated gap after this contig within the scaffold)
--   contig_number (the id number of this contig, later refered to as contig_# in other tables)
--   contig_start_super_base (the start position of the contig within the supercontig, allowing gaps to be negative)
--   modified_contig_start_base (the start position of the contig within the supercontig, not allowing gaps to be negative)
--   modified_bases_in_super (the size of the supercontig, not allowing gaps to be negative)

DROP TABLE IF EXISTS `links`;
CREATE TABLE `links` (
  `super_id` int(10) default NULL,
  `bases_in_super` int(10) default NULL,
  `contigs_in_super` int(10) default NULL,
  `ordinal_number` int(10) default NULL,
  `contig_length` int(10) default NULL,
  `gap_before_contig` int(10) default NULL,
  `gap_after_contig` int(10) default NULL,
  `contig_number` int(11) default NULL,
  `contig_start_super_base` int(11) default NULL,
  `modified_contig_start_base` int(11) default NULL,
  `modified_bases_in_super` int(11) default NULL,
  KEY `links_ordinal_number` (`ordinal_number`),
  KEY `links_super_ordinal` (`super_id`,`ordinal_number`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `ma`
--
-- DESCRIPTION
--  This table is used to store multiple alignments
--  idname the orfid that is linked to this alignment
--  ma (The text for the multiple alignment)
--  type (The format type of the alignment file)
--  
DROP TABLE IF EXISTS `ma`;
CREATE TABLE `ma` (
  `idname` varchar(30) default NULL,
  `ma` longtext,
  `type` varchar(30) default NULL,
  `description` varchar(255) default NULL,
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  KEY `ma_idname_idx` (`idname`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


--
-- Table structure for table `ma_annotation`
--
 
DROP TABLE IF EXISTS ma_annotation;
CREATE TABLE ma_annotation (
  id int(11) NOT NULL auto_increment,
  ma_id int(11) default NULL,
  `type` varchar(30) default NULL,
  annotation longtext,
  PRIMARY KEY  (id),
  KEY ma_annotation_ma_id (ma_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
 

--
-- Table structure for table `news`
--
-- DESCRIPTION
--  This table will store news stories that can be accessed via the news link on the web page
--   id (primary key to the news story)
--   title (The title of the news story)
--   body (The full body of the news story)
--   short_body (A short version of the story to show in reduced descriptions)
--   news_date (The date of the news story)

DROP TABLE IF EXISTS `news`;
CREATE TABLE `news` (
  `id` int(11) NOT NULL auto_increment,
  `title` text,
  `body` text,
  `short_body` text,
  `news_date` date default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `notes`
--
-- DESCRIPTION
--  This table is to create notes. It is currently not used.

DROP TABLE IF EXISTS `notes`;
CREATE TABLE `notes` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(20) default NULL,
  `heading` varchar(255) default NULL,
  `note_text` text,
  `note_dt` date default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `orf_reassign`
--
-- DESCRIPTION
--  This table will store the old orfid if an orf got assigned a new orfid in this assembly

DROP TABLE IF EXISTS `orf_reassign`;
CREATE TABLE `orf_reassign` (
  `old_orf` varchar(20) default NULL,
  `new_orf` varchar(20) default NULL,
  KEY `orf_reassign_old_orf_idx` (`old_orf`),
  KEY `orf_reassign_new_orf_idx` (`new_orf`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `orfs`
--
-- DESCRIPTION
--  This table will store the Open Reading Frames.  It currently has the limitation in that it does not
--  store gene models, it only stores the coding sequence of the orf and only has one start and stop
--  so some massaging of the data must be done if trying to store gene models in here.
--   orfid (a unique id for the orf)
--   sequence (the nt sequence of the orf)
--   annotation (a annotation text, not used any more, the annotation table is now used)
--   annotation_type (not used anymore, the annotation table is now used)
--   source (a free text annotation of the source of the orf call)
--   delete_fg (Y or N, determines if the orf is marked as deleted)
--   contig (the contig location of the orf, with contig_# notation)
--   start (the start location of the orf within the contig)
--   stop (the stop location of the orf within the contig)
--   direction (the direction of the orf within the contig, + or -
--   attributes (not used anymore)
--   old_orf (not used anymore)
--   TestCode  (P or F, the result of the testcode test)
--   CodonScore (not used)
--   CodonPreference (P or F, the result of the codon preference test)
--   TestScore (The numerical result of the testcode test)
--   GeneScan (P or F, the result of the genescan test)
--   GeneScanScore (the numerical result of the genescan test)
--   CodonUsage (the numerical result of the codon usage for this orf)
--   CodonPreferenceScore (the numerical result of the codon preference test)
--   orf_name (an optional free text name for an orf
--   delete_user_id -> user.id (The id of the user who last marked this orf as deleted)
--   last_updated (a timestamp of when this orf was last updated)

DROP TABLE IF EXISTS `orfs`;
CREATE TABLE `orfs` (
  `orfid` int(11) NOT NULL auto_increment,
  `sequence` text,
  `annotation` text,
  `annotation_type` varchar(30) default NULL,
  `source` varchar(30) default NULL,
  `delete_fg` char(1) default NULL,
  `delete_reason` varchar(20) default NULL,
  `contig` varchar(20) default NULL,
  `start` int(11) default NULL,
  `stop` int(11) default NULL,
  `direction` char(1) default NULL,
  `attributes` varchar(200) default NULL,
  `old_orf` char(1) default NULL,
  `TestCode` char(1) default NULL,
  `CodonScore` double default NULL,
  `CodonPreference` char(1) default NULL,
  `TestScore` double default NULL,
  `GeneScan` char(1) default NULL,
  `GeneScanScore` double default NULL,
  `CodonUsage` float default NULL,
  `CodonPreferenceScore` float default NULL,
  `orf_name` varchar(25) default NULL,
  `delete_user_id` int(11) default NULL,
  `last_updated` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`orfid`),
  KEY `delete_fg_orfid_idx` (`delete_fg`),
  KEY `contig_start_stop_orfs_idx` (`contig`,`start`,`stop`),
  KEY `orfs_start_idx` (`start`),
  KEY `orfs_stop_idx` (`stop`),
  KEY `orfs_direction_idx` (`direction`),
  KEY `orfs_orf_name_idx` (`orf_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `orftosage`
--
-- DESCRIPTION
--  This table lists the particular sage tags and if they have been annotated as matching a particular orf and in what respect they
--  match that orf.
DROP TABLE IF EXISTS `orftosage`;
CREATE TABLE `orftosage` (
  `orfid` int(11) default NULL,
  `tagid` int(11) default NULL,
  `tagtype` varchar(25) default NULL,
  `unique_genome_fg` char(1) default NULL,
  `unique_trans_fg` char(1) default NULL,
  `tagmapid` int(11) default NULL,
  `manual_fg` char(1) default NULL,
  `assignment_type` varchar(40) default NULL,
  KEY `orftosage_orfid_idx` (`orfid`),
  KEY `orftosage_tagidorfid_idx` (`tagid`,`orfid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `orthopara`
--
-- DESCRIPTION
--  This table is currently not used.  It was planned to be used to hold orthologs and paralogs to specific genes
--  to be later used for analysis.

DROP TABLE IF EXISTS `orthopara`;
CREATE TABLE `orthopara` (
  `idname` varchar(30) default NULL,
  `db_id` int(11) default NULL,
  `db_xref` varchar(30) default NULL,
  KEY `orthopara_idname` (`idname`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `phylo_current`
--
-- DESCRIPTION
--  This table is used to store the currently running phlyogenetic analysis

DROP TABLE IF EXISTS `phylo_current`;
CREATE TABLE `phylo_current` (
  `id` int(11) NOT NULL default '0',
  `idname` varchar(30) default NULL,
  `sequence_type_id` int(11) default NULL,
  `translate` char(1) default NULL,
  `sequence` longtext,
  `type` varchar(30) default NULL,
  `options` varchar(255) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `phylo_pipe`
--
-- DESCRIPTION
--  This table is used to store all of the phylogenetic analysis to be run from the cluster.

DROP TABLE IF EXISTS `phylo_pipe`;
CREATE TABLE `phylo_pipe` (
  `id` int(11) NOT NULL auto_increment,
  `idname` varchar(30) default NULL,
  `sequence_type_id` int(11) default NULL,
  `translate` char(1) default NULL,
  `sequence` longtext,
  `type` varchar(30) default NULL,
  `options` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `reads`
--
-- DESCRIPTION
--  This table is used to store all of the read sequences of an assembly.

DROP TABLE IF EXISTS `reads`;
CREATE TABLE `reads` (
  `read_id` int(10) NOT NULL auto_increment,
  `read_name` varchar(20) default NULL,
  `center_name` varchar(60) default NULL,
  `plate_id` varchar(20) default NULL,
  `well_id` varchar(20) default NULL,
  `template_id` varchar(20) default NULL,
  `library_id` varchar(20) default NULL,
  `trace_end` varchar(20) default NULL,
  `trace_direction` varchar(20) default NULL,
  `placed` varchar(20) default NULL,
  `status` varchar(20) default NULL,
  PRIMARY KEY  (`read_id`),
  KEY `reads_read_name_idx` (`read_name`),
  KEY `reads_center_name_idx` (`center_name`),
  KEY `reads_trace_dir_idx` (`trace_direction`),
  KEY `reads_template_read` (`template_id`,`read_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `reads_assembly`
--
-- DESCRIPTION
--  This table is used to store the particular location of a assembly read in this current assembly.

DROP TABLE IF EXISTS `reads_assembly`;
CREATE TABLE `reads_assembly` (
  `read_name` varchar(20) default NULL,
  `read_status` varchar(20) default NULL,
  `read_len_untrim` int(10) default NULL,
  `first_base_of_trim` int(10) default NULL,
  `read_len_trim` int(11) default NULL,
  `contig_number` int(11) default NULL,
  `contig_length` int(11) default NULL,
  `trim_read_in_contig_start` int(11) default NULL,
  `trim_read_in_contig_stop` int(11) default NULL,
  `orientation` char(1) default NULL,
  `read_pair_name` varchar(20) default NULL,
  `read_pair_status` varchar(20) default NULL,
  `read_pair_contig_number` int(11) default NULL,
  `observed_insert_size` int(11) default NULL,
  `given_insert_size` int(11) default NULL,
  `given_insert_std_dev` int(11) default NULL,
  `observed_inserted_deviation` float default NULL,
  KEY `reads_assem_name_idx` (`read_name`),
  KEY `reads_assem_contig_idx` (`contig_number`),
  KEY `reads_assem_pair_idx` (`read_pair_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `reads_bases`
--
-- DESCRIPTION
--  This table is used to store the assembly read sequence information

DROP TABLE IF EXISTS `reads_bases`;
CREATE TABLE `reads_bases` (
  `read_name` varchar(20) default NULL,
  `bases` text,
  KEY `reads_bases_read_name_idx` (`read_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `reads_quality`
--
-- DESCRIPTION
--  This table is used to store the assembly read quality information

DROP TABLE IF EXISTS `reads_quality`;
CREATE TABLE `reads_quality` (
  `read_name` varchar(20) default NULL,
  `quality` text,
  KEY `read_quality_read_name_idx` (`read_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `sage_library_names`
--
-- DESCRIPTION
--  This table is used to store the name of the sage library names and subtotals of the total number of tags per library.

DROP TABLE IF EXISTS `sage_library_names`;
CREATE TABLE `sage_library_names` (
  `library` varchar(20) default NULL,
  `name` varchar(255) default NULL,
  `short_name` varchar(15) default NULL,
  `priority` int(11) default NULL,
  `total` int(11) default NULL,
  `total_filtered` int(11) default NULL,
  UNIQUE KEY `library` (`library`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `sage_results`
--
-- DESCRIPTION
--  This table is used to store the results of the sage experiment

DROP TABLE IF EXISTS `sage_results`;
CREATE TABLE `sage_results` (
  `tagID` int(11) default NULL,
  `library` varchar(20) default NULL,
  `result` int(11) default NULL,
  UNIQUE KEY `tagID` (`tagID`,`library`),
  KEY `sage_results_result_tag` (`result`,`tagID`),
  KEY `sage_results_result_library` (`result`,`library`),
  KEY `sage_results_library` (`library`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


--
-- Table structure for table `sage_tags`
--
-- DESCRIPTION
--  This will list the sage tag id along with the complete sequence of the sage tag.

DROP TABLE IF EXISTS `sage_tags`;
CREATE TABLE `sage_tags` (
  `tagID` int(11) NOT NULL default '0',
  `sequence` varchar(30) default NULL,
  PRIMARY KEY  (`tagID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `sage_temp`
--
-- DESCRIPTION
--  This was originaly a temporary table, but has now become more permanant. This will show all of the possible sage
--  tags that overlap with a particular orf's transcript and what the direction is in relation to the orf.

DROP TABLE IF EXISTS `sage_temp`;
CREATE TABLE `sage_temp` (
  `tagid` int(11) default NULL,
  `start` int(11) default NULL,
  `direction` char(1) default NULL,
  `orfid` int(11) default NULL,
  `orf_direction` char(1) default NULL,
  `tagtype` varchar(25) default NULL,
  `tagmapid` int(11) default NULL,
  KEY `sage_temp_tagid_orfid` (`tagid`,`orfid`),
  KEY `sage_temp_orfid` (`orfid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `sequence_search`
--
-- DESCRIPTION
--  This table is used for the sequence searching pipeline and gets stored with different searches to be run via
--  the cluster from the generic_search.pl script
--   id (a primary key)
--   idname (the definition of this varies depending on the sequence_type. If it is an orf, then this is the orfid, a orfspace becomes contig_#_start_stop, etc.
--   sequence_type_id -> sequence_type.id
--   db_id -> db.id
--   algorithm_id -> algorithms.id
--   sequence  (the sequence to be searched)
--   translate (Y or N, defines whether the sequence needs to be translated before run the the search)

DROP TABLE IF EXISTS `sequence_search`;
CREATE TABLE `sequence_search` (
  `id` int(11) NOT NULL auto_increment,
  `idname` varchar(30) default NULL,
  `sequence_type_id` int(11) default NULL,
  `db_id` int(11) default NULL,
  `algorithm_id` int(11) default NULL,
  `sequence` longtext,
  `translate` char(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `sequence_type`
--
-- DESCRIPTION
--  Denotes a sequence type, such as orf, read, orfspace, etc
--   id (a primary key)
--   type (the name of the type)

DROP TABLE IF EXISTS `sequence_type`;
CREATE TABLE `sequence_type` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(20) default NULL,
  PRIMARY KEY  (`id`),
  KEY `sequence_type_type_id_idx` (`type`,`id`),
  KEY `sequence_type_id_type_idx` (`id`,`type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `stats`
--
-- DESCRIPTION
--  This table is used to store various stats that get loaded by the create_stats.pl script
--   statistic (the free text description of the statistic)
--   value (the actual value of the statistic)
--   type  (Used to group statistics together under similar types)

DROP TABLE IF EXISTS `stats`;
CREATE TABLE `stats` (
  `statistic` varchar(255) default NULL,
  `value` text,
  `type` varchar(40) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `tagmap`
--
--  DESCRIPTION
--   This table is used with sage for assigning sage tags to specific parts of the genome

DROP TABLE IF EXISTS `tagmap`;
CREATE TABLE `tagmap` (
  `tagID` int(11) default NULL,
  `contig` varchar(20) default NULL,
  `start` int(11) default NULL,
  `stop` int(11) default NULL,
  `direction` char(1) default NULL,
  `assignment` varchar(20) default NULL,
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `tagID` (`tagID`,`contig`,`start`,`stop`,`direction`),
  KEY `start_tagmap_idx` (`start`),
  KEY `stop_tagmap_idx` (`stop`),
  KEY `tagmap_contig_start_stop_dir_idx` (`contig`,`start`,`stop`,`direction`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `taxon`
--
-- DESCRIPTION
--  NCBI Taxonomy table import

DROP TABLE IF EXISTS `taxon`;
CREATE TABLE `taxon` (
  `taxon_id` int(10) unsigned NOT NULL auto_increment,
  `ncbi_taxon_id` int(10) default NULL,
  `parent_taxon_id` int(10) unsigned default NULL,
  `node_rank` varchar(32) default NULL,
  `genetic_code` tinyint(3) unsigned default NULL,
  `mito_genetic_code` tinyint(3) unsigned default NULL,
  `left_value` int(10) unsigned default NULL,
  `right_value` int(10) unsigned default NULL,
  PRIMARY KEY  (`taxon_id`),
  UNIQUE KEY `right_value` (`right_value`),
  UNIQUE KEY `left_value` (`left_value`),
  UNIQUE KEY `ncbi_taxon_id` (`ncbi_taxon_id`),
  KEY `taxon_parent_taxon_id_taxon_id_idx` (`parent_taxon_id`,`taxon_id`),
  KEY `taxon_taxon_id_parent_taxon_id_idx` (`taxon_id`,`parent_taxon_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `taxon_name`
--
-- DESCRIPTION
--  NCBI Taxonomy table import

DROP TABLE IF EXISTS `taxon_name`;
CREATE TABLE `taxon_name` (
  `taxon_id` int(10) unsigned NOT NULL default '0',
  `name` varchar(255) NOT NULL default '',
  `name_class` varchar(32) NOT NULL default '',
  UNIQUE KEY `taxon_id` (`taxon_id`,`name`,`name_class`),
  KEY `taxnamename` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `templates`
--
-- DESCRIPTION
--  This table deals with keeping track of the various templates and page names for the web site
--   template_file (the file of the template (omiting directory) that is used for this page_name)
--   page_name (the name of the page, which is called via ?page=page_name from the site script)
--   id (a primary key)

DROP TABLE IF EXISTS `templates`;
CREATE TABLE `templates` (
  `template_file` varchar(25) default NULL,
  `page_name` varchar(30) default NULL,
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `page_name` (`page_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `tree`
--
-- DESCRIPTION
--  This table will store tree formated text from files
--   idname (the orfid related to this tree)
--   tree (the tree text)
--   type (the format of the tree file)
--   id (primary key)
--   ma_id -> ma.id (the related multiple alignment for this tree)
--   description (a free text description of the process used in creating this tree)

DROP TABLE IF EXISTS `tree`;
CREATE TABLE `tree` (
  `idname` varchar(30) default NULL,
  `tree` longtext,
  `type` varchar(30) default NULL,
  `id` int(11) NOT NULL auto_increment,
  `ma_id` int(11) default NULL,
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `tree_annotation`
--
 
DROP TABLE IF EXISTS tree_annotation;
CREATE TABLE tree_annotation (
  id int(11) NOT NULL auto_increment,
  tree_id int(11) default NULL,
  `type` varchar(30) default NULL,
  annotation longtext,
  PRIMARY KEY  (id),
  KEY tree_annotation_tree_id (tree_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


--
-- Table structure for table `user`
--
-- DESCRIPTION
--  This table will list the users able to log onto this database via the web interface
--   id (a primary key)
--   user_name (the user login name)
--   first_name (first name of the user)
--   last_name (last name of the user)
--   active_fg (Y or N, will determine if the user account is active or disabled)
--   password (a hashed password created using the mysql password("mypassword") function
--   email (the email address of the user)
--  institution (the University or Institution of the user

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL auto_increment,
  `user_name` varchar(25) default NULL,
  `first_name` varchar(25) default NULL,
  `last_name` varchar(25) default NULL,
  `active_fg` char(1) default NULL,
  `password` varbinary(41) default NULL,
  `email` varchar(255) default NULL,
  `institution` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `user_user_name` (`user_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `user_rights`
--
-- DESCRIPTION
--  This table holds the access rights of users. It can store rights to sage libraries and annotation rights.
--   id (a primary key)
--  userid -> user.id
--  rights (a value that will specify the rights to the specific type
--  type (a description of the category of the specific access rights)

DROP TABLE IF EXISTS `user_rights`;
CREATE TABLE `user_rights` (
  `id` int(11) NOT NULL auto_increment,
  `userid` int(11) default NULL,
  `rights` varchar(40) default NULL,
  `type` varchar(30) default NULL,
  PRIMARY KEY  (`id`),
  KEY `user_rights_userid_idx` (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;

