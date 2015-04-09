#!/usr/local/bin/perl

# command.pl - read a command from the user and return a result code
# Part of Citadel/Quux 
# David Pirmann (pirmann@quuxuum.org)
# 6/18/1998

#===========================================================================
# What's in this file:
# storage of all the commands, what they do, and descriptive help
# getcmd routine which reads the kbd for a command and returns a code.
# a negative return code will print the roomname as well as the msg.
# then return abs($ret)
#===========================================================================


#===========================================================================
# set up a pack template of top level key commands and their descriptions
#===========================================================================
$template = "i A30 A80";

%commands = ( 
	      "a", pack($template, -1, "Abandon Room", ''),
	      "c", pack($template, 3, "Chat", ''),
	      "d", pack($template, 4, "See Room Description", ''),
	      "e", pack($template, 5, "Enter Message", ''),
	      "f", pack($template, 6, "Read Forward", ''),
	      "g", pack($template, 7, "Goto", ''),
	      "h", pack($template, 8, "Help", ''),
	      "i", pack($template, 9, "Info System", ''),
	      "j", pack($template, 10, "Jump/Goto Room", ''),
	      "k", pack($template, 11, "Known Rooms", ''),
	      "l", pack($template, 12, "Read Last Five", ''),
	      "m", pack($template, 13, "Goto Mail", ''),
	      "n", pack($template, 14, "Read New", ''),
	      "o", pack($template, 15, "Read Old Reverse", ''),
	      "p", pack($template, 16, "Read Last Ten", ''),
	      "r", pack($template, 18, "Read Reverse", ''),
	      "s", pack($template, -19, "Skip", ''),
	      "t", pack($template, 20, "Terminate", ''),
	      "u", pack($template, 21, "Ungoto", ''),
	      "w", pack($template, 23, "Who is on...", ''),
	      "x", pack($template, 24, "Express Message", ''),
	      "y", pack($template, 25, "Your Fortune", ''),
	      "z", pack($template, 26, "Zap (forget) Room", ''),
	      "?", pack($template, 8, "Help", ''),
	      "#", pack($template, 27, "Read Last #", ''),
	      "@", pack($template, 28, "Date & Time", ''),
	      "%", pack($template, 41, "Set Wholist Comment", ''),
	      "\027", pack($template, 42, "Alternate Wholist", ''),
	      "\024", pack($template, 43, "Uptime", ''),
	      "\004", pack($template, 29, "Terminate", '')
	      );

delete $commands{'c'} unless ($CONFIG{'FEATURE_ENABLE_CHAT'}>0);
delete $commands{'i'} unless ($CONFIG{'FEATURE_ENABLE_INFO'}>0);
delete $commands{'y'} unless ($CONFIG{'FEATURE_ENABLE_FORTUNE'}>0);
delete $commands{'x'} unless ($CONFIG{'FEATURE_ENABLE_XMSG'}>0);

# oct = printf (%o, ascii)

# reserved codes for future use
#	     "b", pack($template, 3, "", ''),
#	     "q", pack($template, 17, "", ''),
#	     "v", pack($template, 22, "", ''),
#	     "y", pack($template, 25, "", ''),

#===========================================================================
# dot commands and their descriptions
#===========================================================================

%extcommands = ( 
		".ac", pack($template, 30, "Create Room", "Create a new room"),
		".ab", pack($template, 80, "Clear a Bbswho entry", "Clear a Bbbswho entry"),
		".ad", pack($template, 31, "Enter Room Description", "Enter the description of the current room"),
		".ae", pack($template, 32, "Edit Room", "Edit properties of the current room"),
		".ak", pack($template, 33, "Kickout User", "Kickout a user"),
		".ai", pack($template, 34, "Invite User", "Invite a user"),
		".ax", pack($template, 35, "Kill (Ax) Room", "Kill (remove) the current room"),
		".at", pack($template, 36, "Room Stats", "See room stats"),
		".au", pack($template, 37, "User Edit", "Edit user information"),
		".av", pack($template, 38, "Validate", "Validate new users"),
		".a!", pack($template, 40, "Kill Pid", "Kill an errant bbs user pid"),
		".a(", pack($template, 44, "Show %ENV", "Show the environment"),
		".aw", pack($template, 39, "Who Knows Room", "See the invitees in the current room"),
		".al", pack($template, 0, "Log", "Show log entries"),
		".cb", pack($template, 50, "Biography", "Change your Biography"),
		".cc", pack($template, 51, "Configuration", "Change your Configuration/Registration"),
		".cp", pack($template, 53, "Password", "Change your Password"),
		".ee", pack($template, 60, "Message With Editor", "Enter a new message using the editor"),
		".em", pack($template, 5,  "Message", "Enter a new message in this room"),
		".eu", pack($template, 62, "Message Unformatted", "Enter an unformatted message - control-D to exit upload"),
		".ew", pack($template, 63, "Message Without Editor", "Enter a new message with the input sucker"),
		".rf", pack($template, 6,  "Forward", "Read all messages forward"),
		".rl", pack($template, 12, "Last Five", "Read last five messages posted"),
		".rn", pack($template, 14, "New", "Read new messages in current room"),
		".ro", pack($template, 15, "Old Reverse", "Read old messages in reverse order"),
		".rp", pack($template, 16, "Last Ten", "Read last ten messages posted"),
		".rr", pack($template, 18, "Reverse", "Read all messages in reverse order"),
		".rs", pack($template, 74, "System Configuration", "See some details about the system configuration"),
		".rt", pack($template, 81, "System Statistics", "See some details regarding user/post statistics"),
		".ru", pack($template, 75, "User", "Read user profiles/biographies"),
		".ry", pack($template, 76, "Yourself", "Read your own profile/account statistics"));

%fourcommands = ( 
		  ".alu", pack($template, 78, "User Log", "Show user log"),
		  ".ala", pack($template, 79, "Action Log", "Show action log"),
		  );


# return code 77 = .Z Zapped Room List, see below.

#===========================================================================
# getcmd
# returns an integer to be switched upon...
#===========================================================================
sub getcmd {
    my ($curr_rm, $lastcmd) = @_;
    my ($char, $string, $done, $x, $ochar);

FIRSTLETTER:
    $done = 0;
    while (!$done) {
	$char = &getkey;
	$char =~ tr/A-Z/a-z/;
	
	if ($char eq ' ' && $USER{'smartspace'}>0) {         #implement "smartspace"
	    if ( $lastcmd == 14 ||
		 $lastcmd == 6 ||
		 $lastcmd == 12 ||
		 $lastcmd == 15 ||
		 $lastcmd == 16 ||
		 $lastcmd == 18 ||
		 $lastcmd == 27) {
		$char = 'g';
	    } elsif ( $lastcmd == 7 ||     # goto
		      $lastcmd == 13 ||    # goto mail
		      $lastcmd == 1 ||     # abandon
		      $lastcmd == 19 ||    # skip
		      $lastcmd == 21) {     # ungoto
		$char = 'n';
	    } else {
		goto FIRSTLETTER;
	    }
	    my ($ret, $msg, $help) = unpack ($template, $commands{$char});
	    print "$msg\n";
	    return (abs($ret)); #return a positive code.
	} elsif ($char eq '.') {
	    $string="."; print ".";
	    $done=1; #jump out
	} else { 
	    foreach $x (sort keys %commands) {
		if ($char eq $x) {
		    my ($ret, $msg, $help) = unpack ($template, $commands{$x});
		    print "$msg";
		    print " $Room_Names{$curr_rm}" if ($ret < 0);
		    print "\n";
		    return (abs($ret)); #return a positive code.
		} 
	    } 
	}
    }

#okay if we're here then we have a dot in our string.
#lets get another char.
	
  SECONDLETTER:
    $done = 0;
    while (!$done) {
	
	$char = &getkey;
	$char =~ tr/A-Z/a-z/;
	$ochar = ord($char);
	
	if (($char eq 'a') && (($USER{'axlevel'} >= $CONFIG{'AXLEVEL_AIDE'}) || ($Roomaide_Room{$curr_rm}>0))) {
            #only allow aides to run aide commands
	    $msg = "Aide "; print "$msg"; $done=1;
	} elsif ($char eq 'c') {
	    $msg = "Configure "; print "$msg"; $done=1;
	} elsif ($char eq 'e') {
	    $msg = "Enter "; print "$msg"; $done=1;
	} elsif ($char eq 'r') {
	    $msg = "Read "; print "$msg"; $done=1;
	} elsif ($char eq 'g') {
	    print "Jump/Goto Room: ";
	    return (10); # some code for dotgoto
	} elsif ($char eq 'z') {
	    print "Zapped Room List";
	    return (77); # some code for display zapped rooms
	} elsif ($char eq '?') {
	    print "\n\n";
	    print "A... Aide Commands\n"
		if (($USER{'axlevel'} >= $CONFIG{'AXLEVEL_AIDE'}) || ($Roomaide_Room{$curr_rm}>0));
	    print "C... Configuration Commands\n";
	    print "E... Enter Message Commands\n";
	    print "R... Read Message/Info Commands\n";
	    print "G... Goto Room\n";
	    print "Z... Zapped Room List\n";
	    print "\n$Room_Names{$curr_rm}"; # hack! hack!
	    ($Roomaide_Room{$curr_rm}>0) ? print "# ." : print "> .";
	} elsif ( $ochar == 8 || $ochar == 127 || $ochar == 21 || $ochar==23) {
	    &back(1);
	    goto FIRSTLETTER;
	} elsif ($ochar==10) {
	    return (0); # really returning 0 - no command returned
	} 
    }
    
    $string .= $char;

# so now we have ".X" in $string, lets get a third character and see 
# if what they've typed matches anything in the cmds arry
    
THIRDLETTER:
    $done = 0;
    while (!$done) {
	
	$char = &getkey;
	$char =~ tr/A-Z/a-z/;
	$ochar = ord($char);
	
	if ($char eq '?') {
	    print "?\n\n";
	    foreach $x (sort keys %extcommands) {
		# $string has for example .c and $x would have things like .cc
		if ( $string eq substr ($x, 0, 2)) {
		    ($ret, $msg2, $help) = unpack ($template, $extcommands{$x});
		    $x =~ s/$string//; $x =~ tr/a-z/A-Z/;
		    print "$x.... $help\n";
		}
	    }
	    print "\n$Room_Names{$curr_rm}"; # hack! hack!
            ($Roomaide_Room{$curr_rm}>0) ? print "# .$msg" : print "> .$msg";

	    goto THIRDLETTER;
	}
	
	if ($ochar==8 || $ochar==127 || $ochar==23) {
	    &back(length($msg));
	    $string = substr($string, 0, length($string)-1); # so remove the bad char and loop	    
	    goto SECONDLETTER;
	}

	if ($ochar==21) {
	    &back(length($msg)+1);
	    $string = '';
	    goto FIRSTLETTER;
	}

	return 0 if ($ochar==10);

	foreach $x (sort keys %extcommands) {
	    if ("$string$char" eq $x) {
		($ret, $msg2, $help) = unpack ($template, $extcommands{$x});
		if ($ret > 0) {
		    print "$msg2\n";
		    return ($ret); #return out
		} else {
		    print "$msg2 ";
		    $string .= $char;
		    goto FOURTHLETTER;
		}
	    } 
	} 
	# if we get here we didn't find $string in %extcommands
    }


FOURTHLETTER:
    $done = 0;
    while (!$done) {
	
	$char = &getkey;
	$char =~ tr/A-Z/a-z/;
	$ochar = ord($char);
	
	if ($char eq '?') {
	    print "?\n\n";
	    foreach $x (sort keys %fourcommands) {
		# $string has for example .cc and $x would have things like .ccc
		if ( $string eq substr ($x, 0, 3)) {
		    my ($ret, $msg, $help) = unpack ($template, $fourcommands{$x});
		    $x =~ s/$string//; $x =~ tr/a-z/A-Z/;
		    print "$x.... $help\n";
		}
	    }
	    print "\n$Room_Names{$curr_rm}"; # hack! hack!
            ($Roomaide_Room{$curr_rm}>0) ? print "# .$msg$msg2 " : print "> .$msg$msg2 ";
	    goto FOURTHLETTER;
	}
	
	if ($ochar==8 || $ochar==127 || $ochar==23) {
	    &back(length($msg2)+1);
	    $string = substr($string, 0, length($string)-1); # so remove the bad char and loop	    
	    goto THIRDLETTER;
	}
	if ($ochar==21) {
	    &back(length($msg2)+length($msg)+2);
	    $string = '';
	    goto FIRSTLETTER;
	}

	return 0 if ($ochar==10);

	foreach $x (sort keys %fourcommands) {
	    if ("$string$char" eq $x) {
		($ret, $msg3, $help) = unpack ($template, $fourcommands{$x});
		print "$msg3\n";
		return ($ret); #return out
	    } 
	} 
	# if we get here we didn't find $string in %extcommands
    }




} # end getcmd

#===========================================================================
# print version and return
#===========================================================================
print "Version: " 
    . localtime( (stat(__FILE__))[9]) 
    . " " 
    . __FILE__ 
    . "\n"
    if ($DEBUG);

1;
