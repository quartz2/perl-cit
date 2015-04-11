-- MySQL dump 10.13  Distrib 5.5.42, for Linux (x86_64)
--
-- Host: localhost    Database: bbs
-- ------------------------------------------------------
-- Server version	5.5.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `cit_config`
--

DROP TABLE IF EXISTS `cit_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cit_config` (
  `property` varchar(50) NOT NULL DEFAULT '',
  `comment` varchar(100) DEFAULT NULL,
  `value` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`property`),
  KEY `property_value` (`property`,`value`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cit_config`
--

LOCK TABLES `cit_config` WRITE;
/*!40000 ALTER TABLE `cit_config` DISABLE KEYS */;
INSERT INTO `cit_config` VALUES ('DEFAULT_AX_NEWUSER','Access level of a new user?','1'),('DEFAULT_AX_VALIDUSER','Access level of a normal, validated user?','3'),('DEFAULT_AX_MAKEROOM','Minimum access level to create rooms?','4'),('DEFAULT_AX_LOBBYPOST','Minimum access level to post in lobby?','4'),('DEFAULT_USER_REGISTERED','Default setting of registered flag','0'),('DEFAULT_USER_PERMANENT','Default setting of permanent flag','0'),('DEFAULT_USER_LASTOLD','Default setting of lastold flag','0'),('DEFAULT_USER_EXPERT','Default setting of expert flag','0'),('DEFAULT_USER_PAUSE','Default setting of pause flag','1'),('DEFAULT_USER_PROMPT','Default setting of room prompt flag','1'),('DEFAULT_USER_HIDE','Default registration privacy flag','1'),('DEFAULT_USER_EDITOR','Default use of editor flag','0'),('DEFAULT_USER_SMARTSPACE','Default use of smartspace mode','1'),('DEFAULT_USER_MARCHMODE','Default use of march mode','0'),('DEFAULT_USER_SCREENWIDTH','Default user screenwidth','80'),('DEFAULT_USER_SCREENLENGTH','Default user screenlength','24'),('DEFAULT_USER_TIMELIMIT','Default timelimit for users in seconds','10800'),('DEFAULT_MSGS_DAYS','Max number of days to retain messages (per room)','180'),('DEFAULT_MSGS_MAX','Max messages to retain per room','200'),('DEFAULT_HANDLEMAX','Max letters in handle - refer to database before changing.','50'),('DEFAULT_PASSWDMAX','Max letters in a password.','8'),('DEFAULT_ROOMNAMEMAX','Max letters in a room name - refer to database before changing.','50'),('FEATURE_SLEEPING','How long in seconds to idle out a user?','3600'),('FEATURE_REGISCALL','Users must register on or before call #?','1'),('FEATURE_AIDE_ZAP','Allow aides to zap rooms?','1'),('FEATURE_KICKOUT_ZAP','Zapping a private room = automatic kickout?','1'),('FEATURE_ENABLE_MAIL','Enable posting to the Mail room?','1'),('FEATURE_ENABLE_EDITOR','Enable use of an external editor?','1'),('FEATURE_POSTER_DELETE','Allow poster to delete his/her own messages?','1'),('FEATURE_USER_BIOS','Allow users to enter biographies?','0'),('FEATURE_CREATE_AIDE','Users who create rooms become roomaides by default?','0'),('FEATURE_ENABLE_CHAT','Enable C-Chat command key?','0'),('FEATURE_ENABLE_XMSG','Enable X-Xpress Message command key?','0'),('FEATURE_ENABLE_FORTUNE','Enable Y-Your Fortune command key?','1'),('FEATURE_ENABLE_INFO','Enable I-Info System command key?','0'),('FEATURE_SHOW_SENT_MAIL','Show sent mail in mail room?','1'),('FEATURE_ALWAYS_PROMPT','Force users to have room prompts?','0'),('FEATURE_AIDE_PROMPT','Force aides to have room prompts?','0'),('FEATURE_USER_BIO_MAX','Count in bytes for max length of user bio.','800'),('FEATURE_ROOM_DESC_MAX','Count in bytes for max length of room desc.','800'),('FEATURE_MAX_ROOMS','Max number of rooms in system.','250'),('BBSDIR','Home directory of the bbs.','/'),('SC_NODENAME','A short name of this bbs.','citquux'),('PROG_EDITOR','Path to external editor, relative to bbs homedir.','usr/bin/simped'),('PROG_FORTUNE','Path to fortune command, relative to bbs homedir.','usr/bin/fortune'),('PROG_CHAT','Path to chat command, relative to bbs homedir.','usr/bin/chat'),('FILE_NEWS','','messages/news'),('FILE_ENTER','','messages/entermsg'),('FILE_PROHIBNEW','','messages/prohibnew'),('FILE_SLEEPING','','messages/sleeping'),('FILE_NONEW','','messages/nonew'),('FILE_NEWUSER','','messages/newuser'),('FILE_CHANGEPW','','messages/changepw'),('FILE_HELLO','','messages/hello'),('FILE_REGISTER','','messages/register'),('FILE_HELP','','messages/help'),('FILE_GOODBYE','','messages/goodbye'),('FILE_OPTIONS','','messages/options'),('UL_NORMAL','Normal logout','0'),('UL_DROP','Drop carrier/abnormal exit','1'),('UL_SLEEP','Sleeping','2'),('UL_OFF','Typed \"off\" (never logged in)','3'),('UL_TL','Reached timelimit','4'),('UL_BADPW','Too many bad passwords','5'),('UL_NONEW','New users not allowed','6'),('TYPE_RI','Roomaide permission','1'),('TYPE_ZA','Zapped values','2'),('TYPE_LS','Lastseen values','3'),('TYPE_PR','Private room permissions?','4'),('AXLEVEL_DEL','Marked for deletion','0'),('AXLEVEL_NEW','New user','1'),('AXLEVEL_TWIT','Twit user','2'),('AXLEVEL_NORM','Normal user','3'),('AXLEVEL_PREF','Preferred user','4'),('AXLEVEL_AIDE','Aide','5'),('FEATURE_MAX_MAILMSG','Max number of mail messages per user.','150'),('PROG_STATS','Path to statistics program, relative to bbs homedir.','usr/bin/stats');
/*!40000 ALTER TABLE `cit_config` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-04-11 17:08:41
