# phpMyAdmin SQL Dump
# version 2.5.7
# http://www.phpmyadmin.net
#
# Host: localhost
# Generation Time: Apr 06, 2005 at 10:16 AM
# Server version: 4.1.9
# PHP Version: 4.3.7
# 
# Database : `rotifer`
# 

# --------------------------------------------------------

#
# Table structure for table `annotation`
#

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
  KEY `update_dt_idx` (`update_dt`),
  KEY `annotation_userid_dt_idx` (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

# --------------------------------------------------------

#
# Table structure for table `blast_report_full`
#

DROP TABLE IF EXISTS `blast_report_full`;
CREATE TABLE `blast_report_full` (
  `idname` varchar(255) default NULL,
  `report` longtext,
  `sequence_type_id` int(11) default NULL,
  `db_id` int(11) default NULL,
  `algorithm_id` int(11) default NULL,
  KEY `blast_report_full_read_name_idx` (`idname`),
  KEY `blast_report_full_id_type_idx` (`idname`,`sequence_type_id`),
  KEY `blast_report_full_type_id_idx` (`sequence_type_id`,`idname`),
  KEY `blast_report_full_type_idx` (`sequence_type_id`),
  KEY `blast_report_full_db_id_idx` (`db_id`),
  KEY `blast_report_full_all` (`idname`,`sequence_type_id`,`db_id`,`algorithm_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=4294967295 AVG_ROW_LENGTH=500;

# --------------------------------------------------------

#
# Table structure for table `blast_results`
#

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
  KEY `blast_results_read_name_idx` (`idname`),
  KEY `blast_results_idname_type_idx` (`idname`,`sequence_type_id`),
  KEY `blast_results_type_idx` (`sequence_type_id`),
  KEY `blast_results_all` (`idname`,`sequence_type_id`,`algorithm`,`db`),
  KEY `blast_results_desc_idx` (`description`),
  KEY `blast_results_gi_idx` (`gi`),
  KEY `blast_results_evalue` (`evalue`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

# --------------------------------------------------------

#
# Table structure for table `orfs`
#

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
  PRIMARY KEY  (`orfid`),
  KEY `orfs_orfid_idx` (`orfid`),
  KEY `delete_fg_orfid_idx` (`delete_fg`),
  KEY `contig_start_stop_orfs_idx` (`contig`,`start`,`stop`),
  KEY `orfs_start_idx` (`start`),
  KEY `orfs_stop_idx` (`stop`),
  KEY `orfs_direction_idx` (`direction`),
  KEY `orfs_contig_idx` (`contig`),
  KEY `orfs_orf_name_idx` (`orf_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
