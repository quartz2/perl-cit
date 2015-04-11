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
-- Table structure for table `cit_alog`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cit_alog` (
  `eternal` int(11) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `what` text,
  KEY `eternal` (`eternal`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cit_btmp`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cit_btmp` (
  `eternal` int(11) DEFAULT NULL,
  `ltime` int(11) DEFAULT NULL,
  `tty` varchar(17) DEFAULT NULL,
  `host` text,
  `doing` varchar(36) DEFAULT NULL,
  `custom` varchar(36) DEFAULT NULL,
  `pid` int(11) DEFAULT NULL,
  KEY `eternal_idx` (`eternal`),
  KEY `tty_idx` (`tty`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cit_config`
--

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
-- Table structure for table `cit_flags`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cit_flags` (
  `type` int(11) DEFAULT NULL,
  `eternal` int(11) DEFAULT NULL,
  `roomnum` int(11) DEFAULT NULL,
  `value` int(11) DEFAULT NULL,
  KEY `all_idx` (`type`,`eternal`,`roomnum`),
  KEY `eternal_idx` (`eternal`),
  KEY `roomum_idx` (`roomnum`),
  KEY `eternal_roomum` (`eternal`,`roomnum`),
  KEY `roomum_type` (`roomnum`,`type`),
  KEY `eternal_type` (`eternal`,`type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cit_messages`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cit_messages` (
  `msgnum` int(11) NOT NULL AUTO_INCREMENT,
  `roomnum` int(11) DEFAULT NULL,
  `origroom` int(11) DEFAULT NULL,
  `posttime` int(11) DEFAULT NULL,
  `handle` int(11) DEFAULT NULL,
  `recipient` int(11) DEFAULT NULL,
  `sysname` varchar(8) DEFAULT NULL,
  `anon` int(11) DEFAULT NULL,
  `deleted` int(11) DEFAULT NULL,
  `mread` int(11) DEFAULT NULL,
  `msgtxt` mediumtext,
  PRIMARY KEY (`msgnum`),
  KEY `roomnum_idx` (`roomnum`),
  KEY `handle_idx` (`handle`),
  KEY `recipient_idx` (`recipient`),
  KEY `roomnum_msgnum_idx` (`roomnum`,`msgnum`),
  KEY `msgnum_idx` (`msgnum`),
  KEY `roomnum_recip_handle` (`roomnum`,`recipient`,`handle`)
) ENGINE=MyISAM AUTO_INCREMENT=254875 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cit_rooms`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cit_rooms` (
  `roomnum` int(11) NOT NULL AUTO_INCREMENT,
  `roomname` varchar(50) DEFAULT NULL,
  `postax` int(11) DEFAULT NULL,
  `enterax` int(11) DEFAULT NULL,
  `private` int(11) DEFAULT NULL,
  `anon` int(11) DEFAULT NULL,
  `network` int(11) DEFAULT NULL,
  `editor` int(11) DEFAULT NULL,
  `maxallow` int(11) DEFAULT NULL,
  `expire` int(11) DEFAULT NULL,
  `created` int(11) DEFAULT NULL,
  `desctime` int(11) DEFAULT NULL,
  `description` mediumtext,
  PRIMARY KEY (`roomnum`),
  UNIQUE KEY `roomname_idx` (`roomname`)
) ENGINE=MyISAM AUTO_INCREMENT=129 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cit_ulog`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cit_ulog` (
  `eternal` int(11) DEFAULT NULL,
  `host` text,
  `pid` int(11) DEFAULT NULL,
  `timein` int(11) DEFAULT NULL,
  `timeout` int(11) DEFAULT NULL,
  `posts` int(11) DEFAULT NULL,
  `mread` int(11) DEFAULT NULL,
  `sqlcalls` int(11) DEFAULT NULL,
  `exitstat` int(11) DEFAULT NULL,
  KEY `eternal` (`eternal`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cit_users`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cit_users` (
  `eternal` int(11) NOT NULL AUTO_INCREMENT,
  `handle` varchar(50) DEFAULT NULL,
  `password` varchar(16) DEFAULT NULL,
  `regis` int(11) DEFAULT NULL,
  `perm` int(11) DEFAULT NULL,
  `lastold` int(11) DEFAULT NULL,
  `expert` int(11) DEFAULT NULL,
  `pause` int(11) DEFAULT NULL,
  `prompt` int(11) DEFAULT NULL,
  `hide` int(11) DEFAULT NULL,
  `editor` int(11) DEFAULT NULL,
  `valid` int(11) DEFAULT NULL,
  `smartspace` int(11) DEFAULT NULL,
  `marchmode` int(11) DEFAULT NULL,
  `screenwidth` int(11) DEFAULT NULL,
  `screenlength` int(11) DEFAULT NULL,
  `lastcall` int(11) DEFAULT NULL,
  `firstcall` int(11) DEFAULT NULL,
  `timescalled` int(11) DEFAULT NULL,
  `posted` int(11) DEFAULT NULL,
  `axlevel` int(11) DEFAULT NULL,
  `timelimit` int(11) DEFAULT NULL,
  `timetoday` int(11) DEFAULT NULL,
  `timeonline` int(11) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `addr` varchar(50) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `state` varchar(50) DEFAULT NULL,
  `zip` varchar(50) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `url` varchar(150) DEFAULT NULL,
  `host` text,
  `bio` mediumtext,
  PRIMARY KEY (`eternal`),
  UNIQUE KEY `handle_idx` (`handle`),
  KEY `valid_idx` (`valid`),
  KEY `regis_idx` (`regis`),
  KEY `eternal_handle` (`handle`,`eternal`),
  KEY `password_handle` (`password`,`handle`),
  KEY `eternal_valid_regis` (`eternal`,`valid`,`regis`)
) ENGINE=MyISAM AUTO_INCREMENT=563 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-04-11 16:55:25
