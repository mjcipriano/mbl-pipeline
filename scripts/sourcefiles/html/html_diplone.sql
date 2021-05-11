-- MySQL dump 10.9
--
-- Host: localhost    Database: diplone
-- ------------------------------------------------------
-- Server version	4.1.9

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;

--
-- Table structure for table `html`
--

DROP TABLE IF EXISTS `html`;
CREATE TABLE `html` (
  `template` varchar(20) default NULL,
  `variable` varchar(40) default NULL,
  `value` text,
  UNIQUE KEY `template` (`template`,`variable`),
  KEY `template_2` (`template`),
  KEY `template_3` (`template`,`variable`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `html`
--


/*!40000 ALTER TABLE `html` DISABLE KEYS */;
LOCK TABLES `html` WRITE;
INSERT INTO `html` VALUES ('intro','html_leftcolumn','<h3>Introduction</h3>\r\n<p>This data represents a <i>Diplonema papillatum</i> fosmid sequenced and annotated by Hilary Morrison of the Josephine Bay Paul Center at the Marine Biological Laboratory.</p>'),('default','html_title_text','Diplonema papillatum GMOD'),('default','html_funding','<center><small>Supported by <a href=\"http://www.nih.gov/\" target=\"_blank\">NIH</a>, <a href=\"http://www.nsf.gov/\" target=\"_blank\">NSF</a>,<a href=\"http://www.nasa.gov/\" target=\"_blank\"> NASA</a>, <a href=\"http://jbpc.mbl.edu/jbpc/Pages/foundation.html\" target=\"_blank\">The Josephine Bay Paul and C. Michael Paul Foundation</a>,  <a href=\"http://www.wmkeck.org/\" target=\"_blank\">W.M. Keck Foundation</a>, <a href=\"http://www.monellvetlesen.org/vetlesen/default.htm\" target=\"_blank\">G. Unger Vetlesen Foundation</a>, and <a href=\"http://www.ellisonfoundation.org/index.jsp\" target=\"_blank\">Ellison Medical Foundation</a>.<br>\r\n\r\n\r\nUnless otherwise stated, all material &copy 2004 Bay Paul Center, MBL</small></center>'),('intro','html_rightcolumn',''),('default','assembly_datasnapshot','<table width=\"80%\" border=3><tr><td>Total number of contigs</td><td><b>20</b></td></tr><tr><td>Total number of supercontigs</td><td><b>17</b></td></tr><tr><td>Number of bases in contigs > 5kb</td><td><b>46,033</b></td></tr><tr><td>Number of bases in all contigs</td><td><b>59,877</b></td></tr><tr><td>Number of bases sampled and used in Assembly</td><td><b>424,879</b></td></tr><tr><td>Average Coverage</td><td><b>7.10</b></td></tr><tr><td>Total number of reads sequenced</td><td><b>1,006</b></td></tr><tr><td>Total number of reads used in assembly</td><td><b>706</b></td></tr></table>'),('assembly','html_leftcolumn','<h3>Assembly Data</h3>\r\n<p>Assembly data has been generated by Hilary Morrison and using a semi-automated data analysis  pipeline designed for use with gbrowse</p>'),('assembly','html_rightcolumn',''),('default','html_header','			<center>\r\n			<p><font size=\"+4\" color=\"red\"><b><i>Diplonema papillatum</i> Genome Browser</i></b></font></p>\r\n\r\n			This current version is a development version constructed using the <a href=\"http://www.gmod.org\">Generic Model Organism Database</a> paradigm.</p>			</center>'),('default','html_projectenquiries','Assembly and gene information provided by Hilary Morrison, <a href=\"mailto:morrison@mbl.edu\">morrison@mbl.edu</a>'),('default','html_gmodenquiries','			<center>\r\n			<p><i>This database is hosted by the JBPC <a href=\"http://gmod.mbl.edu\">GMOD Server</a>.  Bug reports and technical problems should be reported to <a href=\"mailto:gmod@lists.mbl.edu\">gmod@lists.mbl.edu</a>.</i></p>\r\n\r\n			</center>'),('default','database_name','diplone'),('default','html_menu','Home | GBrowse | Blast | Assembly | ORFs | SAGE | Download | Pfam | Rfam | Repeats | Help'),('sage','html_leftcolumn','<h3>Introduction</h3>\r\n<p>No SAGE data has been developed for the <i>Diplonema papillatum</i/> fosmid.</p>\r\n<p>SAGE quickly and very affordably detects 21 base nucleotide sequences from every mRNA transcript present in a sampled population of cells. The sequences are called tags and the frequency of these tags determined by SAGE is directly reflective of relative transcript abundance. SAGE thus both identifies genes and their relative levels of expression.</p>\r\n\r\n</ul>\r\n<li><a href=\"http://sciencepark.mdanderson.org/ggeg/sage_fig1_zoom.htm\">Detailed diagram of the SAGE protocol</a>\r\n<li><a href=\"http://www.sagenet.org\">SAGEnet - Online resources for Serial Analysis of Gene Expression</a>\r\n</ul>'),('sage','html_rightcolumn',''),('intro','overview_statistics_footer','                                <i>Statistics updated on an as needed basis.<br>\r\n                                Detailed statistics: <a href=\"?page=assembly\">Assembly</a>, <a href=\"?page=orfs\">ORFs</a>, <a href=\"?page=sage\">SAGE</a></i>\r\n'),('default','sage_datasnapshot',''),('default','readgc_image','<img src=\"/cgi-bin/graph_bar?&x_label=%%20GC&y_label=%23%20Reads&title=Distribution%20of%20GC%20Content&vals=0:0&vals=1:0&vals=2:0&vals=3:0&vals=4:0&vals=5:0&vals=6:0&vals=7:0&vals=8:0&vals=9:0&vals=10:0&vals=11:0&vals=12:0&vals=13:0&vals=14:0&vals=15:0&vals=16:0&vals=17:0&vals=18:0&vals=19:0&vals=20:0&vals=21:0&vals=22:0&vals=23:0&vals=24:0&vals=25:0&vals=26:0&vals=27:0&vals=28:0&vals=29:0&vals=30:0&vals=31:0&vals=32:1&vals=33:3&vals=34:1&vals=35:1&vals=36:1&vals=37:3&vals=38:0&vals=39:6&vals=40:2&vals=41:8&vals=42:13&vals=43:19&vals=44:25&vals=45:26&vals=46:40&vals=47:51&vals=48:30&vals=49:28&vals=50:55&vals=51:37&vals=52:38&vals=53:44&vals=54:40&vals=55:58&vals=56:77&vals=57:90&vals=58:93&vals=59:68&vals=60:67&vals=61:40&vals=62:28&vals=63:10&vals=64:0&vals=65:1&vals=66:0&vals=67:0&vals=68:0&vals=69:1&vals=70:0&vals=71:0&vals=72:0&vals=73:0&vals=74:0&vals=75:0&vals=76:0&vals=77:0&vals=78:1&vals=79:0&vals=80:0&vals=81:0&vals=82:0&vals=83:0&vals=84:0&vals=85:0&vals=86:0&vals=87:0&vals=88:0&vals=89:0&vals=90:0&vals=91:0&vals=92:0&vals=93:0&vals=94:0&vals=95:0&vals=96:0&vals=97:0&vals=98:0&vals=99:0&vals=100:0\">'),('default','orfexpressedgc_image','<img src=\"/cgi-bin/graph_bar?&x_label=%%20GC&y_label=%23%20ORFs&title=Distribution%20of%20GC%20Content%20of%20Expressed%20ORFs&vals=0:&vals=1:&vals=2:&vals=3:&vals=4:&vals=5:&vals=6:&vals=7:&vals=8:&vals=9:&vals=10:&vals=11:&vals=12:&vals=13:&vals=14:&vals=15:&vals=16:&vals=17:&vals=18:&vals=19:&vals=20:&vals=21:&vals=22:&vals=23:&vals=24:&vals=25:&vals=26:&vals=27:&vals=28:&vals=29:&vals=30:&vals=31:&vals=32:&vals=33:&vals=34:&vals=35:&vals=36:&vals=37:&vals=38:&vals=39:&vals=40:&vals=41:&vals=42:&vals=43:&vals=44:&vals=45:&vals=46:&vals=47:&vals=48:&vals=49:&vals=50:&vals=51:&vals=52:&vals=53:&vals=54:&vals=55:&vals=56:&vals=57:&vals=58:&vals=59:&vals=60:&vals=61:&vals=62:&vals=63:&vals=64:&vals=65:&vals=66:&vals=67:&vals=68:&vals=69:&vals=70:&vals=71:&vals=72:&vals=73:&vals=74:&vals=75:&vals=76:&vals=77:&vals=78:&vals=79:&vals=80:&vals=81:&vals=82:&vals=83:&vals=84:&vals=85:&vals=86:&vals=87:&vals=88:&vals=89:&vals=90:&vals=91:&vals=92:&vals=93:&vals=94:&vals=95:&vals=96:&vals=97:&vals=98:&vals=99:&vals=100:\">'),('default','html_subtitle',''),('default','html_site_cgi','/cgi-bin/site'),('download','html_column','$database_name'),('default','orfexpressedcodonusage_image','<img src=\"/cgi-bin/graph_bar?&x_label=Codon%20Usage&y_label=%23%20ORFs&title=Codon%20Usage%20Bias%20of%20Expressed%20ORFs&vals=20:&vals=21:&vals=22:&vals=23:&vals=24:&vals=25:&vals=26:&vals=27:&vals=28:&vals=29:&vals=30:&vals=31:&vals=32:&vals=33:&vals=34:&vals=35:&vals=36:&vals=37:&vals=38:&vals=39:&vals=40:&vals=41:&vals=42:&vals=43:&vals=44:&vals=45:&vals=46:&vals=47:&vals=48:&vals=49:&vals=50:&vals=51:&vals=52:&vals=53:&vals=54:&vals=55:&vals=56:&vals=57:&vals=58:&vals=59:&vals=60:&vals=61:\">'),('default','sagetagmap_datasnapshot',''),('default','read_datasnapshot','<table width=\"80%\" border=3><tr><td>Total Number of Reads Sequenced</td><td><b>1,006</b></td></tr><tr><td>Average Read Length &plusmn; stdev</td><td><b>594.85 &plusmn; 129.48 bp</b></td></tr><tr><td>Fraction of Reads Assembled</td><td><b>70.18%</b></td></tr><tr><td>Fraction of Reads Paired in Assembly</td><td><b>70.18%</b></td></tr><tr><td>Number of Bases Used in Assembly</td><td><b>424,879 bp</b></td></tr><tr><td>Average Shotgun Coverage</td><td><b>7.10 fold</b></td></tr></table>'),('default','contig_datasnapshot','The overall average contig length is 2,993 bp.  50% of all nucleotides lie in contigs of at least 10,207 bp.  The overall GC content is 54.94%<p><p><table width=\"80%\" border=3><tr><td><center>Contig Size</center></td><td><center>Number</center></td><td><center>Coverage of 43 Kbp</center></td></tr><tr><td><center>> 512,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=512000&type=contig\">0</a></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 256,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=256000&type=contig\">0</a></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 128,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=128000&type=contig\">0</a></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 64,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=64000&type=contig\">0</a></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 32,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=32000&type=contig\">0</a></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 16,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=16000&type=contig\">0</a></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 8,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=8000&type=contig\">3</a></center></td><td><center><b>89.96%</b></center></b></td></tr><tr><td><center>> 4,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=4000&type=contig\">4</a></center></td><td><center><b>107.62%</b></center></b></td></tr><tr><td><center>> 2,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=2000&type=contig\">4</a></center></td><td><center><b>107.62%</b></center></b></td></tr><tr><td><center>> 1,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=1000&type=contig\">9</a></center></td><td><center><b>122.13%</b></center></b></td></tr><tr><td><center>all contigs</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=0&type=contig\">20</a></center></td><td><center><b>139.99%</b></center></b></td></tr></table>'),('default','supercontig_datasnapshot','The overall average supercontig length is 3,621 bp.  50% of all nucleotides lie in supercontigs of at least 12,518 bp.<p><p><table width=\"80%\" border=3><tr><td><center>Superontig Size</center></td><td><center>Number</center></td><td><center>Isolated Contigs*</center></td><td><center>Coverage of 43 Kbp</center></td></tr><tr><td><center>> 1,024,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=1024000&type=supercontig\">0</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=1024000&singlet=Y&type=isolated contigs\">0</a></b></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 512,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=512000&type=supercontig\">0</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=512000&singlet=Y&type=isolated contigs\">0</a></b></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 256,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=256000&type=supercontig\">0</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=256000&singlet=Y&type=isolated contigs\">0</a></b></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 128,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=128000&type=supercontig\">0</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=128000&singlet=Y&type=isolated contigs\">0</a></b></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 64,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=64000&type=supercontig\">0</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=64000&singlet=Y&type=isolated contigs\">0</a></b></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 32,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=32000&type=supercontig\">0</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=32000&singlet=Y&type=isolated contigs\">0</a></b></center></td><td><center><b>0.00%</b></center></b></td></tr><tr><td><center>> 16,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=16000&type=supercontig\">1</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=16000&singlet=Y&type=isolated contigs\">0</a></b></center></td><td><center><b>65.32%</b></center></b></td></tr><tr><td><center>> 8,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=8000&type=supercontig\">2</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=8000&singlet=Y&type=isolated contigs\">1</a></b></center></td><td><center><b>94.59%</b></center></b></td></tr><tr><td><center>> 4,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=4000&type=supercontig\">3</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=4000&singlet=Y&type=isolated contigs\">2</a></b></center></td><td><center><b>112.25%</b></center></b></td></tr><tr><td><center>> 2,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=2000&type=supercontig\">4</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=2000&singlet=Y&type=isolated contigs\">2</a></b></center></td><td><center><b>119.11%</b></center></b></td></tr><tr><td><center>> 1,000 bp</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=1000&type=supercontig\">8</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=1000&singlet=Y&type=isolated contigs\">6</a></b></center></td><td><center><b>129.68%</b></center></b></td></tr><tr><td><center>all supercontigs</center></td><td><b><center><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=0&type=supercontig\">17</a></center></td><td><center><b><a href=\"?page=assembly_overview&width=800&max_bases=1000000000&min_bases=0&singlet=Y&type=isolated contigs\">15</a></b></center></td><td><center><b>143.95%</b></center></b></td></tr></table><br><i>* Isolated contigs are treated as additional supercontigs.  The number given is a subset of the total, not an addition to the total number of supercontigs.</i>'),('default','overview_datasnapshot','<table width=\"80%\" border=3><tr><td>Total Number of Contigs</td><td><b>20</b></td></tr><tr><td>Total Number of Supercontigs</td><td><b>17</b></td></tr><tr><td>Average Shotgun Coverage</td><td><b>7.10</b></td></tr><tr><td>Estimated Closure (of 43 Kbp)</td><td><b>139.99%</b></td></tr><tr><td>Predicted Open Reading Frames</td><td><b>30</b></td></tr></table>'),('SAGEhelp','html_column','<p><h3>Cluster Analysis Help</h3>\r\nRecommended cluster analysis directions:\r\n<ul> \r\n<li>Download <a href=\"http://bonsai.ims.u-tokyo.ac.jp/~mdehoon/software/cluster/software.htm\">CLUSTER 3.0 </a> and  <a href=\"http://genome-www.stanford.edu/~alok/TreeView\">TreeView.</a></li>\r\n<li>Select which libraries to include, minimum tag count, etc (make sure export format says CLUSTER3.0).</li>\r\n<li>Hit the submit button.  This will create a text file called <b>sageresults.txt.</b></li>\r\n<li>Open Cluster 3.0.  Type in the name of the text file (sageresults.txt) in the job name box.</li>\r\n<li>Click on the Adjust data tab.  Check <b>log transformation data, genes and arrays under median center</b> and click <b>APPLY.</b></li>\r\n<li>Click on the Hierarchical tab.  Check <b>Cluster</b> and <b>Correlation (centered)</b> for BOTH genes and arrays.</li>\r\n<li>Click on Average Linkage.  This will create a .cdt file called <b>sageresults.cdt.</b></li>\r\n<li>Now open TreeView folder and click on TreeView.jar.</li>\r\n<li>Go to File and open the text file you just created (sageresults.cdt).</li>\r\n<br>\r\nNote:  Other programs such as <a href=\"http://cluto.ccgb.umn.edu/\">wCLUTO</a>, <a href=\"http://ccgb.umn.edu/software/java/apps/TableView/\">TableView</a>, and <a href=\"http://telethon.bio.unipd.it/bioinfo/IDEG6/readme.html\">IDEG6</a> may be used for additional/other analysis.\r\n</ul>\r\n\r\nTag type codes found in the cluster data are abbreviated as:\r\n<ul> \r\n<li>PS=Primary Sense</li>\r\n<li>PA=Primary Antisense</li>\r\n<li>AS=Alternate Anitisense</li>\r\n<li>AA=Alternate Antisense</li>\r\n<li>UK=Unknown.</li>\r\n</ul>\r\n</p>'),('default','sagelibraries_datasnapshot',''),('default','orfexpressedperlibrary_image','<img src=\"/cgi-bin/graph_bar?&x_label=Library&y_label=%23%20Expressed%20ORFs&title=Expressed%20ORFs%20Per%20Library&x_label_skip=1\">'),('default','database_version','diplone'),('default','rperprimarytag_image','<img src=\"/cgi-bin/graph_bar?&x_label=R-Value&y_label=%23%20tags&title=R-Value%20per%20Primary%20SAGE%20Tag&vals=0:0&vals=1:0&vals=2:0&vals=3:0&vals=4:0&vals=5:0&vals=6:0&vals=7:0&vals=8:0&vals=9:0&vals=10:0&vals=11:0&vals=12:0&vals=13:0&vals=14:0&vals=15:0&vals=16:0&vals=17:0&vals=18:0&vals=19:0&vals=20:0&vals=21:0&vals=22:0&vals=23:0&vals=24:0&vals=25:0&vals=26:0&vals=27:0&vals=28:0&vals=29:0&vals=30:0&vals=31:0&vals=32:0&vals=33:0&vals=34:0&vals=35:0&vals=36:0&vals=37:0&vals=38:0&vals=39:0&vals=40:0&vals=41:0&vals=42:0&vals=43:0&vals=44:0&vals=45:0&vals=46:0&vals=47:0&vals=48:0&vals=49:0&vals=50:0\">'),('default','rperprimarytag_over','0 tags with greater then R-Value of 50 are not shown.'),('default','orfsequencelength_image','<img src=\"/cgi-bin/graph_bar?&x_label=ORF AA Size&y_label=%23%20Number%20ORFs&title=Size%20Distrubution%20(amino%20acid)%20of%20ORFs&x_label_skip=20&vals=60:1&vals=110:1&vals=140:2&vals=160:2&vals=170:1&vals=190:1&vals=200:1&vals=220:2&vals=240:1&vals=250:1&vals=300:2&vals=320:2&vals=340:1&vals=350:1&vals=360:2&vals=390:1&vals=400:1&vals=430:1&vals=450:1&vals=560:1&vals=580:1&vals=600:1&vals=730:1&vals=820:1\">'),('general_help','html_column','<h2><a name=\"selecting\">Selecting a Region of the Genome</a></h2>\r\n\r\n<p>\r\n\r\n<img src=\"/img/general_help/genhelp1.jpg\" align=\"RIGHT\">\r\n\r\nTo select a region of the genome to view, enter its name in the text\r\nfield labeled \"Landmark or Region\".  Here are some examples:\r\n\r\n<dl>\r\n <dt><b>a chromosome name</b>\r\n <dd>Chromosome assignments are not currently available for <i>Diplonema papillatum</i>\r\n     <p>\r\n <dt><b>keywords</b>\r\n\r\n <dd>You can enter keywords to search the databases of annotations, BLASTP hits to GenBank and SwissProt protein entries, and HMMER hits to the <a href=\"http://pfam.wustl.edu\">PFam protein domains</a>.  This will produce a listing of Open Reading Frames with annotations or BLAST/HMMER hits containing these keywords, with measures of the significance of the match.  Examples: <i>histone, thioredoxin, Entamoeba</i>.      <p>\r\n <dt><b>a contig or clone name</b>\r\n <dd>You can enter the name of a assembly landmark such as a\r\n     sequence read, clone, contig, or supercontig.  Examples: <i>contig_2325, read:GLL0088D06, supercontig_2758</i>.\r\n     <p>\r\n <dt><b>an accession number</b>\r\n\r\n <dd>You can enter a GenBank or SwissProt accession number (proteins only) as all Open Reading Frames are associated with a database of BLASTP hits.\r\n     <p>\r\n <dt><b>ORF and SAGE tag IDs</b>\r\n <dd>You can jump to specific ORFs or SAGE tags using their identifiers.  These identifiers are immortal - they will not change as the assembly changes.  Examples: <i>orf:14753, sagetag:1000</i>.\r\n       <p>\r\n <dt><b>tRNAs</b>\r\n <dd>You can jump to specific tRNA using their identifiers.  Example: <i>trna:leu</i>.\r\n\r\n</dl>\r\n\r\n<h3>The Overview and Detail Panels</h3>\r\n\r\n<p>\r\n\r\nIf the landmark is found in the database, the browser will display the\r\nregion of the genome it occupies.  The region is displayed in two\r\ngraphical panels:\r\n\r\n<p>\r\n\r\n<center>\r\n<table>\r\n<tr>\r\n<td><b>Overview Panel</b></td><td width=\"100%\"><center><img src=\"/img/general_help/genhelp2.jpg\" align=\"CENTER\"></center></td>\r\n</tr>\r\n<tr>\r\n\r\n<td><b>Detail Panel</b></td><td width=\"100%\"><center><img src=\"/img/general_help/genhelp3.jpg\" align=\"CENTER\"></center></td>\r\n</tr>\r\n</table>\r\n</center>\r\n\r\n<p>\r\n\r\n<dl>\r\n <dt><b>overview panel</b>\r\n <dd>This panel displays the genomic context, typically a large portion of the sequence\r\n     assembly such as a supercontig (scaffold) or contig.  A red rectangle indicates the region of the genome that is\r\n     displayed in the detail panel.  This rectangle may appear as\r\n     a single line if the detailed region is relatively small.\r\n     <p>\r\n <dt><b>detail panel</b>\r\n\r\n <dd>This panel displays a zoomed-in view of the genome corresponding\r\n     to the overview\'s red rectangle.  The detail panel consists of\r\n     one or more tracks showing annotations and other features that\r\n     have been placed on the genome.  The detail panel is described\r\n     at length later.     </dl>\r\n\r\n<p>\r\n\r\nIf the requested landmark is not found, the browser will display a\r\nmessage to this effect.\r\n\r\n<h3>Specifying the Landmark Type</h3>\r\n\r\n<p>\r\n\r\nSome kinds of landmarks have been qualified with their type using the format <i>type:landmark</i>.  For\r\nexample, to look up the SAGE tag 1000 in the\r\n<i>Marinobacter</i>DB, you would search for\r\n\r\n<i>sagetag:1000</i>.\r\n\r\n<p>\r\n\r\nIn the case of clashes between names, such as an ORF and a SAGE tag both\r\nnumbered 1000, you can use the name type to choose which landmark you\r\nmean.\r\n\r\n<p>\r\n\r\n<ul><li>read:</li> <li>contig_</li> <li>supercontig_</li> <li>orf:</li> <li>sagetag:</li> <li>trna:</li>\r\n\r\n</ul>\r\n\r\n<h3>Viewing a Precise Region around a Landmark</h3>\r\n\r\n<p>\r\n\r\nYou can view a precise region around a landmark using the notation\r\n<i>landmark:start..stop</i>, where <i>start</i> and <i>stop</i> are\r\nthe start and stop positions of the sequence relative to the landmark.\r\nThe beginning of the feature is position 1. To view position 1000 to 5000 of contig_2325, you would search for <i>contig_2325:1000..5000</i>.</p>\r\n\r\n<p>In the case of complex\r\nfeatures, such as genes, the \"beginning\" is defined by the database\r\nadministrator.  For example, in the <i>Diplonema papillatum</i> data set,\r\nposition 1 of a predicted gene is the AUG at the beginning of the CDS.  To view the region that begins 100 base pairs upstream of the AUG of ORF 1000 and\r\nends 500 bases downstream of it, you would search for\r\n<i>orf:1000:-99..500</i>.</p>\r\n\r\n<p>This offset notation will work correctly for negative strand features\r\nas well as positive strand features.  The coordinates are always\r\nrelative to the feature itself.  For example, to view the <b>reverse compliment</b> of position 1000 to 5000 of contig_2325, you would search for <i>contig_2325:5000..1000</i>.</p>\r\n\r\n<h3>Searching for Keywords</h3>\r\n\r\n<p>\r\n\r\nAnything that you type into the \"Landmark or Region\" textbox that\r\nisn\'t recognized as a landmark will be treated as a full text search\r\nacross the feature database.  This will find comments or other feature\r\nnotations that match the typed text.  These include annotations, blast hits, and PFam hits.\r\n\r\n<p>\r\n\r\nIf successfull, the browser will present you with a list of possible\r\nmatching landmarks and their comments.  You will then be asked to\r\nselect one to view.  To see this in action, try typing \"kinase\" into\r\nthe \"Landmark or Region\" box.\r\n\r\n<hr>\r\n\r\n<h2><a name=\"navigation\">Navigation</a></h2>\r\n\r\n<img src=\"/img/general_help/genhelp4.jpg\" align=\"RIGHT\">\r\n\r\n<p>\r\n\r\nOnce a region is displayed, you can navigate through it in a number of\r\nways:\r\n\r\n<dl>\r\n <dt><b>Scroll left or right with the &lt;&lt;, &lt;,\r\n     &gt; and &gt;&gt; buttons</b>\r\n <dd>These buttons, which appear in the \"Scroll/Zoom\" section of the\r\n     screen, will scroll the detail panel to the left or right.  The\r\n     <b>&lt;&lt;</b> and <b>&gt;&gt;</b> buttons scroll an entire\r\n     screen\'s worth, while <b>&lt;</b> and <b>&gt;&gt;</b> scroll a\r\n     half screen.\r\n     <p>\r\n\r\n <dt><b>Zoom in or out using the \"Show XXX Kbp\" menu.</b>\r\n <dd>Use menu that appears in the center of the \"Scroll/Zoom\" section\r\n     to change the zoom level.  The menu item name indicates the\r\n     number of base pairs to show in the detail panel.  For example,\r\n     selecting the item \"100 Kbp\" will zoom the detail panel so as\r\n     to show a region 100 Kbp wide.\r\n     <p>\r\n <dt><b>Make fine adjustments on the zoom level using the \"-\" and\r\n     \"+\" buttons.</b>\r\n <dd>Press the <b>-</b> and <b>+</b> buttons to change the zoom level\r\n     by small increments.\r\n     <p>\r\n\r\n <dt><img src=\"/img/general_help/genhelp5.gif\" align=\"RIGHT\">\r\n     <b>Recenter the detail panel by clicking on its scale</b>\r\n <dd>The scale at the top of the detail panel is live.  Clicking on\r\n     it will recenter the detail panel around the location you\r\n     clicked.  This is a fast and easy way to make fine adjustments\r\n     in the displayed region.\r\n     <p>\r\n <dt><b>Get information on a feature by clicking on it</b>\r\n <dd>Clicking on a feature in the detail view will link to a page\r\n     that displays more information about it.\r\n     <p>\r\n <dt><img src=\"/img/general_help/genhelp6.jpg\" align=\"RIGHT\">\r\n     <b>Jump to a new region by clicking on the overview panel</b>\r\n\r\n <dd>Click on the overview panel to immediately jump\r\n     to the corresponding region of the genome.\r\n</dl>\r\n\r\n<br clear=\"all\">\r\n\r\n<hr>\r\n\r\n<h2><a name=\"detail\">The Detail Panel</a></h2>\r\n\r\n<p>\r\n\r\nThe detailed view is composed of a number of distinct tracks which\r\nstretch horizontally from one end of the display to another.  Each\r\ntrack corresponds to a different type of genomic feature, and is\r\ndistinguished by a distinctive graphical shape and color.\r\n\r\n<p>\r\n\r\n<center>\r\n\r\n<img src=\"/img/general_help/genhelp7.jpg\" align=\"CENTER\">\r\n</center>\r\n\r\n<p>\r\n\r\nThe key to the tracks is shown at the bottom of the detail panel.  For\r\nmore information on the source and nature of the track, click on the\r\ntrack label in the \"Search Settings\" area (discussed below).\r\n\r\n<h3>Customizing the Detail Panel</h3>\r\n\r\nYou can customize the detailed display in a number of ways:\r\n\r\n<p>\r\n\r\n<dl>\r\n <dt><b>Turn tracks on and off using the \"Search Settings\" area</b>\r\n <dd><img src=\"/img/general_help/genhelp8.jpg\" border=\"1\"><p>\r\n\r\n     The panel labeled \"Search Settings\" contains a series of\r\n     checkboxes.  Each checkbox corresponds to a track type.  Selecting\r\n     the checkbox activates its type.  Select the label to the\r\n     right of the checkbox to display a window that provides more\r\n     detailed information on the track, such the algorithm used to\r\n     generate it, its author, or citations.\r\n     <p>\r\n <dt><b>Change the properties of the tracks using the \"Set Track Options\" button</b>\r\n <dd><img src=\"/img/general_help/genhelp9.jpg\" border=\"1\"><p>\r\n     This will bring up a window that has detailed settings for each of the tracks.\r\n     Toggle the checkbox in the \"Show\" column to turn the track on\r\n     and off (this is the same as changing the checkbox in the Search\r\n     Settings area). Change the popup menu in the \"Format\" column to\r\n     alter the appearance of the corresponding track.  Options include:\r\n     <i>Compact</i> which forces all items in the track onto a single overlapping line without\r\n     labels or descriptions; <i>Expand</i>, which causes items to bump each other so that\r\n     they don\'t collide; and <i>Expand &amp; Label</i>, which causes items to be labeled\r\n     with their names and a brief description.  The default, <i>Auto</i> will choose compact\r\n     mode if there are too many features on the track, or one of the expanded modes if there\r\n     is sufficient room.  Any changes you make are remembered the next time you visit the browser.\r\n     Press <b>Accept Changes and Return...</b> when you are satisfied with the current options.\r\n     <p>\r\n\r\n <dt><b>Change the order of tracks using the \"Set Track Options\" button</b>\r\n <dd>The last column of the track options window allows you to change the order of the\r\n     tracks.  The popup menu lists all possible feature types in alphabetic order.  Select\r\n     the feature type you wish to assign to the track.  The window should refresh with the\r\n     adjusted order automatically, but if it doesn\'t, select the \"Refresh\" button to see the\r\n     new order.\r\n    </dl>\r\n\r\n<hr>\r\n\r\n<h2><a name=\"upload\">Uploading Your Own and 3d Party Annotations</a></h2>\r\n\r\n<p>\r\n\r\nThis browser supports third party annotations, both your own private\r\nannotations and published annotations contributed by third parties.\r\n\r\n<h3>Uploading Your Own Annotations</h3>\r\n\r\n<img src=\"/img/general_help/genhelp10.jpg\">\r\n\r\n<p>\r\n\r\nTo view your own annotations on the displayed genome, go to the bottom\r\nof the screen and click on the <b>Browse...</b> button in the file\r\nupload area.  This will prompt you for a text file containing your\r\nannotations. See the <a href=\"http://gmod.mbl.edu/gb/gbrowse/diplone09screads?help=annotation\">annotation format help</a> document for information on\r\nhow to create this file.\r\n\r\n<p>\r\n\r\nOnce loaded, tracks containing these annotations will appear on the\r\ndetailed display and you can control them just like any of the\r\nbuilt-in tracks.  In addition new <b>Edit</b>, <b>Delete</b> and\r\n\r\n<b>Download</b> buttons will appear in the file upload area.  As their\r\nnames imply, these buttons allow you to edit the uploaded file,\r\ndownload it, or delete it completely.\r\n\r\n<p>\r\n\r\nThe date at which the uploaded file was created or last modified is\r\nprinted next to its name.  If there are a manageable number of\r\nannotated areas, GBrowse will create links that allow you to jump\r\ndirectly to them.\r\n\r\n<p>\r\n\r\nYou may upload as many files as you wish, but be advised that the\r\nperformance of the browser may decrease if there are many large\r\nuploads to process.\r\n\r\n<h3>Viewing 3d Party Annotations</h3>\r\n\r\n<p>\r\n\r\nTo view 3d party annotations, the annotations must be published on a\r\nreachable web server and you must know the annotation file\'s URL.\r\n<p>\r\n\r\n<img src=\"/img/general_help/genhelp11.jpg\">\r\n\r\n<p>\r\n\r\nAt the bottom of the browser window is a text box labeled \"Enter\r\nRemote Annotation URL\".  Type in the URL and then press \"Update URLs\".\r\nThe system will attempt to upload the indicated URL.  If successful,\r\nthe data will appear as one or more new tracks.  Otherwise you will\r\nbe alerted with an error message.\r\n\r\n<p>\r\n\r\nYou may add as many remote URLs as you wish.  To delete one, simply\r\nerase it and press \"Update URLs\" again.\r\n\r\n<hr>\r\n\r\n<h2><a NAME=\"bugs\">Software Bugs</a></h2>\r\n\r\n<p><i>MarinobacterDB</i> is continually evolving, so this software may contain bugs.  Please report any that\r\nyou suspect to <a href=\"mailto:gmod@lists.mbl.edu\">gmod@lists.mbl.edu</a>, along with whatever information that you can\r\nprovide as to what you were doing when the bug appeared.</p>\r\n\r\n<p> '),('general_help','html_header','<center>\r\n\r\n<p><font size=\"+4\" color=\"red\"><b>General Help</b></font></p>\r\n\r\n</center>  '),(NULL,NULL,NULL),('default','orfgc_image','<img src=\"/cgi-bin/graph_bar?&x_label=%%20GC&y_label=%23%20ORFs&title=Distribution%20of%20GC%20Content%20of%20ORFs&vals=0:&vals=1:&vals=2:&vals=3:&vals=4:&vals=5:&vals=6:&vals=7:&vals=8:&vals=9:&vals=10:&vals=11:&vals=12:&vals=13:&vals=14:&vals=15:&vals=16:&vals=17:&vals=18:&vals=19:&vals=20:&vals=21:&vals=22:&vals=23:&vals=24:&vals=25:&vals=26:&vals=27:&vals=28:&vals=29:&vals=30:&vals=31:&vals=32:&vals=33:&vals=34:&vals=35:&vals=36:&vals=37:&vals=38:&vals=39:&vals=40:1&vals=41:&vals=42:&vals=43:&vals=44:1&vals=45:&vals=46:1&vals=47:2&vals=48:&vals=49:&vals=50:&vals=51:&vals=52:&vals=53:1&vals=54:1&vals=55:&vals=56:4&vals=57:5&vals=58:6&vals=59:1&vals=60:6&vals=61:1&vals=62:&vals=63:&vals=64:&vals=65:&vals=66:&vals=67:&vals=68:&vals=69:&vals=70:&vals=71:&vals=72:&vals=73:&vals=74:&vals=75:&vals=76:&vals=77:&vals=78:&vals=79:&vals=80:&vals=81:&vals=82:&vals=83:&vals=84:&vals=85:&vals=86:&vals=87:&vals=88:&vals=89:&vals=90:&vals=91:&vals=92:&vals=93:&vals=94:&vals=95:&vals=96:&vals=97:&vals=98:&vals=99:&vals=100:\">'),('default','orfcodonusage_image','<img src=\"/cgi-bin/graph_bar?&x_label=Codon%20Usage&y_label=%23%20ORFs&title=Codon%20Usage%20Bias%20of%20ORFs&vals=20:&vals=21:&vals=22:&vals=23:&vals=24:&vals=25:&vals=26:&vals=27:&vals=28:&vals=29:&vals=30:&vals=31:&vals=32:&vals=33:&vals=34:&vals=35:3&vals=36:3&vals=37:&vals=38:1&vals=39:1&vals=40:5&vals=41:3&vals=42:2&vals=43:2&vals=44:&vals=45:1&vals=46:1&vals=47:1&vals=48:1&vals=49:&vals=50:2&vals=51:&vals=52:&vals=53:&vals=54:&vals=55:2&vals=56:&vals=57:&vals=58:1&vals=59:&vals=60:&vals=61:1\">'),('default','orf_datasnapshot','<table width=\"80%\" border=3><tr><td>Number of Predicted ORFs</td><td><b><center>30</center></b></td></tr><tr><td>ORFs passing Test Code (test 1)</td><td><b><center>93.33%</center></b></td></tr><tr><td>ORFs passing Gene Scan (test 2)</td><td><b><center>96.67%</center></b></td></tr><tr><td>ORFs passing Codon Preference (test 3)</td><td><b><center>96.67%</center></b></td></tr><tr><td>ORFs passing Two of Three Tests</td><td><b><center>96.67%</center></b></td></tr><tr><td>ORFs with BLAST E-value < 1e-10</td><td><b><center>96.67%</center></b></td></tr><tr><td>ORFs with BLAST E-value < 1e-04</td><td><b><center>96.67%</center></b></td></tr></table>'),('default','domain_datasnapshot','<table width=\"80%\" border=3><tr><td><center>Database:Algorithm</center></td><td><b></b><center>Number of domains</center></td><td><center>Number of distinct domains</center><b></b></td></tr><tr><td><center>Pfam_ls:hmmpfam</center></td><td><b><center>425</center></b></td><td><b><center>362</center></b></td></tr></table>'),('orfs','html_leftcolumn','<h3><center>Gene Prediction Strategy</center></h3>\r\n<p>Gene prediction for at the Bay Paul Center, MBL primarily uses the  \r\ncomputer programs <a  \r\nhref=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=pubmed&dopt=Abstract&list_uids=10556321\">GLIMMER</a>  \r\n\r\nand <a  \r\nhref=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=pubmed&dopt=Abstract&list_uids=10331277\">CRITICA</a>,  \r\n and by manual  \r\ncuration of genes reported in the literature and GenBank.   The terms  \r\n<i>predicted open reading frames</i> or <i>protein coding genes</i> are  \r\nused interchangably. ORFs are presented in  \r\nthe context of gene models which include exons, introns, and the  \r\nuntranslated regions (UTRs) of theoretical or cDNA transcripts.</p>\r\n<p>As the underlying genome assembly approaches closure, effort has  \r\nbeen made to track predicted genes between assemblies.  Each ORF is  \r\nassigned an identification number, its ORF ID.  When a new assembly is  \r\nproduced, existing ORFs are re-mapped to the genome based on 100%  \r\nnucleotide identity, including searches for new additional copies of  \r\nthe gene.  Some ORFs may <i>fall off</i> the assembly if a single (or  \r\nmore) mismatch exists between the ORF nucleotide sequence and assembly  \r\nconsensus.  In this case, a new ORF ID is assigned to the newly  \r\npredicted gene sequence and tools are provided to trace the fate of  \r\nORFs <i>falling off</i> the assembly.  Multiple iterations of <a  \r\nhref=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=pubmed&dopt=Abstract&list_uids=10556321\">GLIMMER</a>  \r\n\r\nand <a  \r\nhref=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=pubmed&dopt=Abstract&list_uids=10331277\">CRITICA</a>  \r\nare performed between assemblies to ensure the most complete gene  \r\nprediction coverage.</p>\r\n<p>A degree of ORF screening is performed to ensure the quality of  \r\npredicted genes.  Partial ORFs are not supported - each ORF must have a  \r\nproper start and stop codon.  This means that partial ORFs will not be  \r\npredicted for the end of assembly contigs.  If same-frame, overlapping  \r\nORFs are predicted that differ in the predicted start codon only, the  \r\ngene prediction giving the longest protein is retained.  As such,  \r\ninitial gene preditions are likely to be overly greedy about start  \r\ncodons until experimental evidence is found to revise the position of  \r\nthe start codon.</p>\r\n<p>ORFs overlapping in different reading frames are retained.  No ORF  \r\nfilters based on ORF length or homology scores are currently in use.   \r\nIntrons are tracked where known from experimental evidence.</p>\r\n<center><h3>Annotation</h3></center>\r\n<p>Annotation of proteins is provided primarily by BLAST (1e<sup>-20</sup> cut-off), except where provided by curation and third party annotation. A number of precompiled results (BLAST, PFam, etc.) are available for each ORF.</p>\r\n\r\n');
UNLOCK TABLES;
/*!40000 ALTER TABLE `html` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

