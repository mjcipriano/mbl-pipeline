DROP TABLE IF EXISTS ma_annotation;
CREATE TABLE ma_annotation (
 id int(11) NOT NULL auto_increment, 
 ma_id int(11) default NULL,
 `type` varchar(30) default NULL, 
 annotation longtext, 
 PRIMARY KEY (id), 
 KEY ma_annotation_ma_id (ma_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS tree_annotation;
CREATE TABLE tree_annotation (
 id int(11) NOT NULL auto_increment, 
 tree_id int(11) default NULL, 
 `type` varchar(30) default NULL, 
 annotation longtext, 
 PRIMARY KEY (id), 
 KEY tree_annotation_tree_id (tree_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
