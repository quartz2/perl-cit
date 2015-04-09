#!/usr/local/bin/perl

# message.pl - routines pertaining to message reading, entering, etc.
# Part of Citadel/Quux 
# David Pirmann (pirmann@quuxuum.org)
# 6/18/1998

#===========================================================================
# enter_message
# handle entering a message, mail, etc.
#===========================================================================
sub enter_message {
    my ($curr_rm, $reternal, $mode) = @_;

    # first, check posting privledges and other conditions for posting
    # if we are in the lobby, the user must be axlevel LOBBYPOST */
    # also check if mail is enabled.

    # hold room is used to return the user to mail after mail to sysop
    my $hold_rm=$curr_rm;

    my @start_hir = &msg_list($curr_rm);
    my $start_hir = scalar @start_hir;

#    print STDERR "curr = $curr_rm ax = $axlevel\n";

    if ($curr_rm == 1) {
	if ($USER{'axlevel'} >= $CONFIG{'DEFAULT_AX_LOBBYPOST'}) {
	    print "Do you really want to post to the Lobby? (Y/N) ";
	    return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm}) 
		unless (&yesno);
	} else {
	    print "Error, can't clutter the Lobby>.\n\n";
	    return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
	}
    }
    if ($curr_rm==2 && (!$CONFIG{'FEATURE_ENABLE_MAIL'}>0)) { 
	print "Error, Mail not available.\n";
	return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
    }

    # from now on, even room aides have full privs to this room.
    # all we need to do is check postax. Everything else should have
    # been checked by now (theoretically)

    my $local_axlevel = $USER{'axlevel'};
    $local_axlevel = $CONFIG{'AXLEVEL_AIDE'} if ($Roomaide_Room{$curr_rm}>0);

#    print STDERR "postax=" . $Room_Flags{"$curr_rm.postax"},
#    "; enterax=" . $Room_Flags{"$curr_rm.enterax"}, 
#    "; axlevel=$local_axlevel\n";

    # check to see if user has sufficient postax
    if ($local_axlevel < $Room_Flags{"$curr_rm.postax"}) {  
	print "Error, you can read but not post here.\n",
	"Also, new users may only post in the room called New Users>\n";
	return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
    }

    &enter_btmp("entermsg");

    &formout($CONFIG{'FILE_ENTER'}) unless ($USER{'expert'}>0);

    my $whoto; my $rhandle;

    # Special case for room 2=mail. If there's an reternal value
    # then we're replying to a message from that user. Otherwise,
    # read a recipient name and convert, shove into reternal.

    if ( $curr_rm==2 ) {

	#must have permission to email
	if ( $local_axlevel >= $CONFIG{'DEFAULT_AX_VALIDUSER'}) { 

	    if ($reternal==0) {
		print "Enter recipient";
		if ($lasthandle) {
		    print " [$lasthandle]: ";
		} else {
		    print ": ";
		}
		$whoto = &getline($CONFIG{'DEFAULT_HANDLEMAX'});
		if (length($whoto)<1) {
		    if ($lasthandle) {
			$whoto=$lasthandle;
		    } else {
			return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
		    }
		} 
		($rhandle, $reternal) = &sql_is_user($whoto);
		if ($reternal<0 && $whoto ne 'sysop') {
		    print "No such user.\n";
		    return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
		} 
		if ($eternal == $reternal) {
		    print "Can't send mail to yourself.\n";
		    return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
		}
	    } else {
		$rhandle=&sql_return_handle($reternal);
	    }
	} else {
	    $whoto = "sysop";
        }
    }
    
    if ($whoto =~ /sysop/i) {
	$hold_rm = 3; # chose to send mail to sysop
    } else {
	$whoto = $rhandle;
    }

    # if the anon flag is positive, it's either optional or forced.
    # if the flag is one, then it's optional. check and either
    # put it up to 2 or reset to 0.

    my $anon=0;
    if ($Room_Flags{"$curr_rm.anon"}==1) {
	print "Anonymous (Y/N)? ";
	if (&yesno) {
	    $anon=2;
	} else {
	    $anon=0;
	}
    } elsif ($Room_Flags{"$curr_rm.anon"}==2) {
	$anon=2;
    } else {
	$anon=0;
    }

    my $posttime = time;

    my @shir = &msg_list($curr_rm);
    my $shir = $shir[$#shir];

    print "(Press ctrl-d when finished)\n" if ( $mode == 1 );

    print "\n  " . localtime($posttime);
    if ($anon>0) {
	print " **ANONYMOUS**";
    } else {
	print " from $USER{'handle'}";
    }
    print " to $whoto" if ($whoto);
    print "\n";

    # mode 0 = use default setting for message input
    # mode 1 = enter unformatted
    # mode 2 = use editor
    # mode 3 = use input sucker

    # editor requested OR default requested and editor on.
    my $string;
    if ( ($mode==2) || ($USER{'editor'}==1 && $mode == 0) && ( -f "$CONFIG{'PROG_EDITOR'}") ) {
	# fire up editor
	if ( ($childpid=fork()) == 0) {
	    &unset_terminal;
	    unlink ("$mytmpfile"); #in case it's still hanging around
#	    print "Running $CONFIG{'BBSDIR'}/$CONFIG{'PROG_EDITOR'} $mytmpfile\n";
	    exec("$CONFIG{'BBSDIR'}/$CONFIG{'PROG_EDITOR'} $mytmpfile");
	    exit ($?);
	} 

	waitpid($childpid,0);
	&set_terminal;

	if ($?>0) { # should be 0
#	    print "Couldn't run the editor.\n";
	    unlink ("$mytmpfile"); #in case it's still hanging around
	    return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
	}

	# when it comes back, snarf it's tmp file turd into $string.
	if (open (TURD, "$mytmpfile")) {
	    #slurp the whole file-- from the Perl FAQ.
	    $string = do { local $/; <TURD> };
	    close (TURD);
	    unlink "$mytmpfile";
	} else {
	    print "Not saving empty message.\n";
	    unlink ("$mytmpfile"); #in case it's still hanging around
	    return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
	}
    } else {
	# mode is either 1 or 3, or it's 0 with input sucker default
	$mode=0 if ($mode==3);
	# 0 for formatted, 1 for unformatted.
	($status, $string) = &input_sucker ($mode);
	if ($status < 0) { #user aborted
	    unlink ("$mytmpfile"); #in case it's still hanging around
	    return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
	}

	if (length($string) < 3) {
	    print "Not saving empty message.\n";
	    unlink ("$mytmpfile"); #in case it's still hanging around
	    return ($Lastseen_Room{$curr_rm},$Lastseen_Room{$curr_rm});
	}
    }
    

#    print "BEFORE FUDGE\n";
#    &show_ords($string);

    $string =~ s/\r\n/\n/g; # convert \r\n to \n

    if ($mode==0) { #formatted
	# strip carriage returns and linefeeds from the text
	# except when the next char is a space
	$string =~ s/\n(\S)/ $1/g; 

    } 
		
    # lose other nonprintables
    $string =~ s/[\000-\011\013-\037\177-\377]//gs; 

    # and trailing \n's
    $string =~ s/\n$//s;     

#    print "AFTER FUDGE\n";
#    &show_ords($string);

    # so post it.

#    print STDERR "enter_msg: Inserting room=$hold_rm\nmsgnum=$msgnum\nhandle=$handle\nrecipient=$reternal\nnode=$SC_NODENAME\nflags=$flags\nmsg=$string\n" if ($DEBUG);

    my $origroom;
    if ($curr_rm==2 and $hold_rm==3) {
	$origroom=2;
    } else {
	$origroom=0;
    }

    # we encode the string to preserve cr/lfs and quote marks
    $string = encode_base64($string);

    &do_sth ( qq(lock tables cit_messages WRITE));
    &do_sth ( qq(insert into cit_messages 
		 (msgnum, roomnum, origroom, posttime, handle, recipient, 
		  sysname, anon, deleted, msgtxt) values 
		 (NULL, $hold_rm, $origroom, $posttime, $eternal,
		  $reternal, '$SC_NODENAME', $anon, 0, '$string')));
    &do_sth ( qq(unlock tables));

    $session_posts++;

    my @end_hir = &msg_list($curr_rm);
    my $end_hir = scalar @end_hir;

    if ( ($end_hir-$start_hir) > 1 ) {
	print "There were messages posted while you were entering.\n";
    }

    unlink ("$mytmpfile"); #in case it's still hanging around
    return ($end_hir[$#end_hir],$end_hir[$#end_hir]);
}


#===========================================================================
# read_message
# actually displays the message to the user's tty
#===========================================================================
sub read_message {

    my ($curr_rm, $msgnum, $handle, $hhandle, $recipient, $posttime, $origroom,
	$sysname, $anon, $deleted, $mread, $msgtxt) = @_;

    my $phandle;
    if ($anon) {
	$phandle = "**ANONYMOUS**";
    } else {
	$phandle = $hhandle;
	$lasthandle=$hhandle;
    }

    my $rhandle;
    if ($recipient) {
	$rhandle = &sql_return_handle($recipient);
    }

    $ptime = localtime($posttime);
    print "\n";
    return 1 if (&inclinecount(1));
    print "   (#${curr_rm}-${msgnum}) $ptime from $phandle ";

    if ($recipient>0) {
	print "to $rhandle ";
	print "(READ) " if ($read==1);
    }

    if ($origroom>0) {
	print "in $Room_Names{$origroom}> ";
    }
    print "@ $sysname" if ($NETWORKED);
    print " *** DELETED ***" if ($deleted);
    print "\n";
    return 1 if (&inclinecount(1));

    return 1 if (&message_format($msgtxt));

    print "\n";
    return 1 if (&inclinecount(1));

    if ($eternal==$recipient) {
	&do_sth ( qq(update cit_messages set mread=1 where msgnum=$msgnum));
    }

    $session_read++;

    return;
}

#===========================================================================
# message_format
# formats the message according to screenwidth
#===========================================================================
sub message_format {
    my ($string) = @_;

    my $elen       = 10;
    my $char       = '';
    my $ns         = '';
    my $charcount  = 0;

# step through string
# if char not equal to cr,
#      if char=space and charcount > $screenwidth
#             print it with a cr and linecount++;
#             newstring=""; charcount=0;
#      otherwise,
#             newstring .= char,  charcount++
# if char equals cr,
#      print the newstring, linecount++
#      newstring="", charcount=0
# if linecount > screenlength
#     print more and wait

#    &show_ords($string);

    #temporary hack until we dump the database again.
#    $string =~ s/[\000-\011\013-\037\177-\377]//gs; 

    foreach my $i (0..length($string)) {
	my $char = substr ($string, $i, 1);
	if ( ord($char) != 10 ) {
	    if ( ($char eq ' ') && ($charcount > $USER{'screenwidth'}-$elen)) {
		print "$ns\n"; $ns=""; $charcount=0; 
		return 1 if (&inclinecount(1));
	    } else {
		$ns .= $char; $charcount++;
	    }
	} else {
	    print "$ns\n"; 
	    $ns="";
	    $charcount=0;
	    return 1 if (&inclinecount(1));
	}
    } # keep going!

    # there might be some remaining chars in ns after the foreach.
    print "$ns\n";
    return 1 if (&inclinecount(1));
    return(0);
}

#===========================================================================
# readmsgs
# this routine is the core of reading messages.
# 
# new forward: mode=0, direction=1, lastseen=some msgnum
# old reverse: mode=0, direction=-1, lastseen=some msgnum
# all forward: mode=1, direction=1, lastseen=0 (or never read before)
# all reverse: mode=1, direction=-1, lastseen=0 (actually last msgnum)
# last X     : mode=1, direction=1, lastseen=negative X
#
# handle the prompt, aide privs for deleting, etc.
#===========================================================================
sub readmsgs {
    my ($curr_rm, $pls, $mode, $direction) = @_;
    my $replied=0; my $high_msg;
    my %rrary;
#    print STDERR "Readmsgs mode=$mode direction=$direction\n" if ($DEBUG);
#    print "ls $Lastseen_Room{$curr_rm}\n";   

    # what follows is a hack. If they have roomaide privs, make them
    # axlevel CONFIG{'AXLEVEL_AIDE'} for this routine only.
    my $local_axlevel = $USER{'axlevel'};
    $local_axlevel = $CONFIG{'AXLEVEL_AIDE'} if ($Roomaide_Room{$curr_rm}>0);

    # need prompt mode on in mail
    if ($curr_rm==2 || $CONFIG{'FEATURE_ALWAYS_PROMPT'} > 0 ) {
	$prompt = 1;
    } else {
	$prompt = $USER{'prompt'};
    }

    if ($CONFIG{'FEATURE_AIDE_PROMPT'}>0 && $local_axlevel==$CONFIG{'AXLEVEL_AIDE'}) {
	$prompt = 1;
    }

    my @msg_list = &msg_list($curr_rm);
    my @init_list=@msg_list;

#    print STDERR "list of msgs @msg_list\n\n";

    my $tot = scalar @msg_list;
    unless ($tot) {
	print "No messages in this room.\n";
	return (0,0);
    }

# Given the mode and direction, now we have to find out the first message 
# to show to the user. 
    
    if ($mode==1) {
	#all forward
	#all reverse
	#last X

	if ($direction>0) { 
	    #all forward or last X
	    
	    if ($pls == 0) {
		# all forward. Should start at the first index in the array.
		$current = 0;
	    } else {
		# last X. Going to start at the index X positions before
		# the end of the array--- or at 0 if there are less than
		# X messages in the array. for Last X pls comes over as
		# a negative pls so first, set it right, then subtract
		# and check if your still in a positive area.
		$pls = abs($pls);
		$current = $#msg_list - $pls+1;
		$current = 0 if ($current < 0);
	    }
	} else {
	    # all reverse. Should quite obviously start at the last index.
	    $current = $#msg_list;
	}

    } else {
	#new forward
	#old reverse

	# For these, we need to find the index containing the first 
	# msgnum which is greater than pls (previous lastseen).
	# If there isn't an msgnum > pls, there's no new messages.
	# If they're reading new forward, error and return. 
	# For old reverse, you start at the very last index in the array.

	# it's possible that 0 is a valid index.
	# we'll use -1 to start with to know the difference

	my $x=-1;
	my $a=0;
	GETX: foreach my $tmp (0..$#msg_list) {
	    #print "Checking index $tmp\n";
	    if ($msg_list[$tmp] > $pls) { 
		#print "Found $msg_list[$tmp] (index $tmp) > pls $pls\n";
		$x=$tmp;
		if ($direction>0) {
		    if ($USER{'lastold'} > 0) {
		#	print "Ok I'm setting x to $a which is $msg_list[$a]\n" if ($DEBUG);
			$x=$a;
		    }
		}
		last GETX;  #jump out when you find the first one.
	    }
	    $a=$tmp;
	} 

	if ($direction>0) {
	    #new forward
	    if ($x<0) { 
		print "No new messages.\n";
		return ($pls,$msg_list[$#msg_list]); #send back whatever they came in with
	    } else {
		$current=$x;
	    }

	} else {
	    #old reverse
	    if ($x<0) {
		$current = $#msg_list;
	    } else {
		$current = $x;
	    }
	}
    } #wow, v.2.0. 

# ok now we have "$current" which will be the index we start reading at. 

    print "current index is $current\n" if ($DEBUG);

    my $rv1; my $rv2;

  READLOOP:
    while (1) {  # the only way out of here is to conditionally return 

	# under what conditions might we exit?
	# user hits stop
	# no more new messages to show (i.e. $current is not an index of msg_list)

	if ($current > $#msg_list || $current < 0) {
	    #pass back the index of the highest one read, and the hir
	    if ($replied > 0) {
#		print "Condition: replied to a msg, returning $replied\n";
		$rv1=$replied;
		$rv2=$replied;
		last READLOOP;
	    } else {
#		print STDERR "Condition: no more msgs, returning hi $high_msg lastseen $msg_list[$high_msg] and hir $msg_list[$#msg_list]\n"; 
		$rv1=$msg_list[$high_msg];
		$rv2=$msg_list[$#msg_list];
		last READLOOP;
	    }
	} # else,

	# start showing the messages at $current index position


	my ($handle,$recipient,$posttime,$origroom,$sysname,$anon,$deleted,$read,$msgtxt) =
	    &get_message($msg_list[$current]);

	my $hhandle = &sql_return_handle($handle);
	$msgtxt = decode_base64($msgtxt);

	if ( ($deleted) && ($local_axlevel<$CONFIG{'AXLEVEL_AIDE'})) {
#	    print "Deleted, Can't display message, $local_axlevel $CONFIG{'AXLEVEL_AIDE'}?\n";
	    ($direction>0) ? $current++ : $current--;
	} elsif (length ($msgtxt)==0) {
	    print "Can't display message?\n";
	    ($direction>0) ? $current++ : $current--;
	} else {

	    #display the message
	    if (&read_message ($curr_rm, $msg_list[$current], $handle, $hhandle, $recipient, $posttime, $origroom,
			       $sysname, $anon, $deleted, $mread, $msgtxt)) {
		if ($replied > 0) {
#			print "Condition: Stopped w/ replied $replied\n";
		    $rv1=$replied;
		    $rv2=$replied;
		    last READLOOP;
		} else {
#			print "Condition: stopped, returning ls $msg_list[$high_msg], hir $msg_list[$#msg_list]\n";
		    $rv1=$msg_list[$high_msg];
		    $rv2=$msg_list[$#msg_list];
		    last READLOOP;
		}
	    }

	    #keep track of the highest one
	    $high_msg=$current unless ($high_msg > $current);
#	    print "current = $current msg_list[cur]=$msg_list[$current], high_msg=$high_msg  ml[hm] = $msg_list[$high_msg]\n";

	    if ($prompt) {

		# how to calculate how many are left? it depends on the direction
		# new or forward, highest index-current
		# old or reverse, current down to 0
		if ($direction>0) {
		    $count = $#msg_list - $current;
		} else {
		    $count = $current;
		}
		
	      PRINTPROMPT: print "<B>ack, <N>ext, <J>ump, <S>top";
		if ($local_axlevel>=$CONFIG{'AXLEVEL_AIDE'}) {
		    if ($anon) {
			print ", <W>ho Posted";
		    }
		    if ($deleted) {
			print ", <U>ndelete";
		    }
		    print ", <M>ove" unless ($curr_rm==2);
		}
		
		if ( ($local_axlevel>=$CONFIG{'AXLEVEL_AIDE'})
		     || ($handle==$eternal && $CONFIG{'FEATURE_POSTER_DELETE'}>0)) {
		    print ", <D>elete" unless (($deleted>0) || ($curr_rm==2));
		}
		
		print ", <R>eply" if ($curr_rm==2);
		
		# keep track of the highest one they've seen this time around
		
		print " ($count) -> ";
		
	      READPROMPT:
		$linecount = 0;
		$option = &retkey('b', 'n', 's', 'd', 'm', 'j', 'u', 'r', ' ', 'w', '~');
		
		if ($option eq 'n' || $option eq ' ') {
		    print "Next\n";
		    ($direction>0) ? $current++ : $current--;
		} elsif ($option eq 's') {
		    print "Stop\n";
		    # not sure we need to return anything special if they stop.
		    # maybe just return the highest. if they goto, everything
		    # gets marked read anyway. but what about skip/abandon.
		    if ($replied > 0) {
#			print "Condition: Stopped w/ replied $replied\n";
			$rv1=$replied;
			$rv2=$replied;
			last READLOOP;
		    } else {
			print "Condition: stopped, returning rv1 $msg_list[$high_msg], rv2 $msg_list[$#msg_list]\n" if ($DEBUG);
			if ($Lastseen_Room{$curr_rm}>$msg_list[$high_msg])  {
			    $rv1=$msg_list[$#msg_list];
			} else {
			    $rv1=$msg_list[$high_msg];
			}
			$rv2=$msg_list[$#msg_list];
			last READLOOP;
		    }
		} elsif ($option eq 'b') {
		    print "Back\n";
		    $count=$current-1;
		    $direction *= -1;
		    ($direction>0) ? $current++ : $current--;
		} elsif ($option eq 'j') {
		    print "Jump\nJump how many? ";
		    my $hj = &getline(5);
		    if ($direction>0) {
			$current=$current+$hj;
		    } else {
			$current=$current-$hj;
		    }
		} elsif ($option eq '~') {
		    goto READPROMPT if ($local_axlevel < $CONFIG{'AXLEVEL_AIDE'});
		    print "Really Delete I'm Serious Now\n";
		    print "Are you sure? ";
		    &really_delete_msg($curr_rm, $msg_list[$current], $eternal) if (&yesno);
		    ($direction>0) ? $current++ : $current--;
		} elsif ($option eq 'd') {
#		    print "poster $handle, eternal $eternal, lax $local_axlevel\n";
		    if ($local_axlevel < $CONFIG{'AXLEVEL_AIDE'}) {
			goto READPROMPT if ($handle!=$eternal ||
					    !($CONFIG{'FEATURE_POSTER_DELETE'}>0));
		    }
		    print "Delete\n";
		    print "Are you sure? ";
		    &delete_msg($curr_rm, $msg_list[$current], $eternal) if (&yesno);
		    ($direction>0) ? $current++ : $current--;
		} elsif ($option eq 'u') {
		    goto READPROMPT if ($local_axlevel < $CONFIG{'AXLEVEL_AIDE'});
		    print "Undelete\n";
		    print "Are you sure? ";
		    &undelete_msg($curr_rm, $msg_list[$current], $eternal) if (&yesno);
		    ($direction>0) ? $current++ : $current--;
		} elsif ($option eq 'w') {
		    goto READPROMPT if ($local_axlevel < $CONFIG{'AXLEVEL_AIDE'} || (!$anon));
		    print "\nPosted by $hhandle\n";
		    goto PRINTPROMPT;
		} elsif ($option eq 'm') {
		    goto READPROMPT if ($local_axlevel < $CONFIG{'AXLEVEL_AIDE'});
		    print "Move\n";
		    &move_message($curr_rm, $msg_list[$current], $eternal);
		    ($direction>0) ? $current++ : $current--;
		} elsif ($option eq 'r') {
		    goto READPROMPT if ($curr_rm!=2);
		    print "Reply\n";
#		    print "Debug: poster $handle, eternal $eternal, lax $local_axlevel\n";
		    if ($handle == $eternal) {
			print "Can't send mail to yourself.\n";
		    } else {
			($replied, undef)=&enter_message($curr_rm, $handle, 0);
			$rrary{$replied}++;
#		    print "x $x y $y high $msg_list[$#high_msg]\n";
# not sure what else needs be done.		    
		    }
		    ($direction>0) ? $current++ : $current--;
		}
	    } else {      #end if_prompt 
		
		# assuming we weren't using prompts;
		# we have to get to the next message somehow
		($direction>0) ? $current++ : $current--;
	    }
	}
    }

#last READLOOP

    if ($curr_rm==2 && $replied>0) {
	my @end_list = &msg_list($curr_rm);

#	print "init list @init_list\n";
#	print "end list @end_list\n";
	print "\n\n";

	my %initary;
	my %endary;
        foreach $x (@init_list) {
	    $initary{$x}++;
	}

	my $count=0;
      FINDLOWMAIL: foreach $highest (@end_list) {
	    unless (exists $initary{$highest}) {
		unless (exists $rrary{$highest}) {
#		    print "$highest appears to be a new message and is not a reply.\n";
		    last FINDLOWMAIL;
		}
	    }
	    $count++;
	}
	#last FINDLOWMAIL
#	print "highest = $end_list[$count] and the one before is $end_list[$count-1] ($count)\n";
	$rv1=$end_list[$count-1];
	$rv2=$rv1;
    }

#    print STDERR "Returning rv1 $rv1 rv2 $rv2\n";
    return($rv1, $rv2); 

}

#===========================================================================
# move_message
# move a message to a different room
#===========================================================================
sub move_message {
    my ($curr_rm, $msgnum, $eternal) = @_;

    if ($curr_rm==2) {
	print "Can't move a message from Mail>.\n";
	return;
    }

    # get a room name
    print "Move to room: ";
    my $newroom=&getline(50);

    unless ($newroom) {
	print "Move cancelled.\n";
	return;
    }

    if ($newroom =~ /^mail$/i) {
	print "Can't move a message to Mail>.\n";
	return;
    }

    # get its eternal
    foreach $x (sort { $a <=> $b } keys %Room_Names) {
	if ($Room_Names{$x} =~ /^$newroom/i ) {
	    
	    if ($x == $curr_rm) {
		print "Can't move to same room!\n";
		return;
	    }

	    # if we move a message to a new room, it'll take it's
	    # sequential chronological place in the new room
	    # meaning some people might never see it if lastseen>msgnum
	    # so, do we "reinsert" the message with a new msgnum??

	    &do_sth ( qq(lock tables cit_messages WRITE));

	    my $sth = &do_sth ( qq(select MAX(msgnum) from cit_messages));
	    my ($last) = $sth->fetchrow;
	    $last++;

	    # set origroom=roomnum
	    # set roomnum=eternal
	    &do_sth ( qq(update cit_messages 
			 set origroom=roomnum,roomnum=$x,msgnum=$last
			 where msgnum=$msgnum and roomnum=$curr_rm));

	    &do_sth ( qq(unlock tables));

	    &cit_alog ($eternal, "moved message $msgnum from $Room_Names{$curr_rm} to $Room_Names{$x}");

	    return;
	}
    }
}

#===========================================================================
# delete_msg
# mark a message as deleted by toggling deleted flag
#===========================================================================
sub delete_msg {
    my ($curr_rm, $message, $eternal) = @_;
    if ($curr_rm == 1) { #i.e., mail room
	print "Cannot delete a mail message after it was sent.\n";
	return;
    }
    &do_sth ( qq(update cit_messages set deleted=1
		 where roomnum=$curr_rm and msgnum=$message));

    &cit_alog ($eternal, "deleted message $message in room $Room_Names{$curr_rm}");
}

#===========================================================================
# really_delete_msg
# delete the row of a message from the database once and for all
# called by the ~ key at the message prompt
#===========================================================================
sub really_delete_msg {
    my ($curr_rm, $message, $eternal) = @_;
    if ($curr_rm == 1) { #i.e., mail room
	print "Cannot delete a mail message after it was sent.\n";
	return;
    }
    &do_sth ( qq(delete from cit_messages 
		 where roomnum=$curr_rm and msgnum=$message));

    &cit_alog ($eternal, "really deleted message $message in room $Room_Names{$curr_rm}");
}

#===========================================================================
# undelete_msg
# toggle the deleted flag back to undelete status
#===========================================================================
sub undelete_msg {
    my ($curr_rm, $message, $eternal) = @_;
    &do_sth ( qq(update cit_messages set deleted=0
		 where roomnum=$curr_rm and msgnum=$message));

    &cit_alog ($eternal, "undeleted message $message in room $Room_Names{$curr_rm}");
}

#===========================================================================
# get_message
# pull the message from the database, called by readmsgs
#===========================================================================
sub get_message {
    my ($msgnum) = @_;    

    my $sth = &do_sth ( qq(select handle,recipient,posttime,origroom,
			   sysname,anon,deleted,mread,msgtxt
			   from cit_messages
			   where msgnum=$msgnum));

    if ( @tmp = $sth->fetchrow ) {
	return @tmp;
    } else {
#	print STDERR "sub get_message: no msg $message \n" if ($DEBUG);
	return -1;
    }
}

#===========================================================================
# msgs_room
# generates an array of roomnum, highest msg in room
#===========================================================================
sub msgs_room {
    my %msarray; my $limit;

    #for regular rooms. normal users can only see non-deleted
    if ($USER{'axlevel'}<$CONFIG{'AXLEVEL_AIDE'}) { 
	$limit = " and deleted=0 ";
    }

    my $sth = &do_sth ( qq(select roomnum,max(msgnum)
			   from cit_messages 
			   where roomnum!=2
			   $limit
			   group by roomnum));
    
    while (my ($rn, $max) = $sth->fetchrow) {
	$msarray{$rn}=$max;
    }
    $sth->finish;

    my $sth = &do_sth ( qq(select max(msgnum)
			   from cit_messages 
			   where roomnum=2
			   and (recipient=$eternal 
			   or handle=$eternal)));

    my ($max) = $sth->fetchrow;
    $sth->finish;
#    print STDERR "msgs_room inserting max $max for room 2\n";
#    print STDERR "msgs_room lsr $Lastseen_Room{2}\n";
    $msarray{2}=$max;

    return %msarray;
}

#===========================================================================
# msg_nums
# returns ($tot, $new) for a curr_rm accounting for the fact 
# that some might be deleted and not visible to the user.
#===========================================================================
sub msg_nums {

    my ($curr_rm) = @_;

    my $limit;

    # normal users can only see non-deleted
    unless ($Roomaide_Room{$curr_rm} > 0 || $USER{'axlevel'} >= $CONFIG{'AXLEVEL_AIDE'}) { 
	$limit = " and deleted=0 ";
    }

    if ($curr_rm==2) {        # show only your from or to.
	if ($CONFIG{'FEATURE_SHOW_SENT_MAIL'}>0) {
	    $limit .= " and (handle=$eternal or recipient=$eternal) ";
	} else {
	    $limit .= " and recipient=$eternal ";
	}
    }

    if (! defined $Lastseen_Room{$curr_rm}) {
	$Lastseen_Room{$curr_rm}=0;
    }

    # first find out the number > lastseen
    my $sth = &do_sth ( qq(select count(*) from cit_messages 
			   where roomnum=$curr_rm
			   and msgnum > $Lastseen_Room{$curr_rm}
			   $limit));

    my ($new) = $sth->fetchrow;
    $sth->finish;

    # then the total
    my $sth = &do_sth ( qq(select count(*) from cit_messages 
			   where roomnum=$curr_rm
			   $limit));

    my ($tot) = $sth->fetchrow;
    $sth->finish;

    return ($tot, $new);
}

#===========================================================================
# sub msg_list
# returns array of all msgnums visible to the user in given room
#===========================================================================
sub msg_list {

    my ($curr_rm) = @_;
    my $limit;
    # normal users can only see non-deleted
    unless ($Roomaide_Room{$curr_rm} > 0 || $USER{'axlevel'} >= $CONFIG{'AXLEVEL_AIDE'}) { 
	$limit = " and deleted=0 ";
    }

    if ($curr_rm==2) {        # show only your from or to.
	if ($CONFIG{'FEATURE_SHOW_SENT_MAIL'}>0) {
	    $limit .= " and (handle=$eternal or recipient=$eternal) ";
	} else {
	    $limit .= " and recipient=$eternal ";
	}
    }

    # first find out the number > lastseen
    my $sth = &do_sth ( qq(select msgnum from cit_messages 
			   where roomnum=$curr_rm
			   $limit
			   order by msgnum));

    my @marray;
    while (my ($new) = $sth->fetchrow) {
	push @marray, $new;
    }
    $sth->finish;
#    print "Debug; message list for room $curr_rm = @marray\n";
    return @marray;
}

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

