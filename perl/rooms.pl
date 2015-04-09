#!/usr/local/bin/perl

# rooms.pl - Routines pertaining to room management
# Part of Citadel/Quux 
# David Pirmann (pirmann@quuxuum.org)
# 6/18/1998

#===========================================================================
# sub create_room, prompt user and insert a new room into the database
#===========================================================================
sub create_room {
    my ($axlevel, $eternal) = @_;

    &enter_btmp("[Create Room]");

    if ($axlevel < $CONFIG{'DEFAULT_AX_MAKEROOM'}) {
	print "Must be user level $AXLEVELS{$CONFIG{'DEFAULT_AX_MAKEROOM'}} ";
	print "to create a room.\n\n";
	return;
    }

    my ($roomname, $postax, $enterax, $private, $anon, $network, 
	$editor, $maxallow, $expire, $unzap, $qws) = 
	&get_room_opts(0);

    if ($qws == 1) {
	print "Ok, not saving.\n\n";
	return;
    }

#    print STDERR "create_room: $roomname px $postax ex $enterax ",
#    "pr $private an $anon nt $network ed $editor mx $maxallow ex $expire\n"
#	if ($DEBUG);

    $roomname=quotemeta($roomname);
    &do_sth ( qq(insert into cit_rooms (roomnum, roomname, postax,
					enterax, private, anon,
					network, editor, maxallow,
					expire, created, description) values
					(NULL, '$roomname', $postax,
					$enterax, $private, $anon,
					$network, $editor, $maxallow,
					$expire, UNIX_TIMESTAMP(), '$description')));

    my $sth = &do_sth ( qq(select roomnum from cit_rooms where
			   roomname='$roomname'));

    my ($num) = $sth->fetchrow;
    $sth->finish;

    &cit_alog ($eternal, "created room $roomname ($num) PR=$private ANON=$anon");

    return $num;
}

#===========================================================================
# sub delete_room; prompt and then remove a room and cleanup the database
#===========================================================================
sub delete_room {
    my ($axlevel, $eternal, $curr_rm) = @_;

    if ($axlevel < $CONFIG{'AXLEVEL_AIDE'}) {
	print "Must be user level $AXLEVELS{$CONFIG{'AXLEVEL_AIDE'}} ";
	print "to delete a room.\n\n";
	return;
    }

    &enter_btmp("[Delete Room]");

    print "Delete room \"$Room_Names{$curr_rm}\"? (Y/N) ";
    return if (!&yesno);
	
    # entry in rooms table.
    # messages stored for this room
    # roomaide, zapped, lastseen, private flags for each user
	
    &do_sth ( qq(delete from cit_rooms    where roomnum=$curr_rm));
    &do_sth ( qq(delete from cit_messages where roomnum=$curr_rm));
    &do_sth ( qq(delete from cit_flags    where roomnum=$curr_rm));

    &cit_alog ($eternal, "deleted room $Room_Names{$curr_rm} ($curr_rm)");

    return;
}

#===========================================================================
# edit_room. Basically the same as create, just update the existing fields
#===========================================================================
sub edit_room {
    my ($curr_rm) = @_;

    if (($USER{'axlevel'} < $CONFIG{'AXLEVEL_AIDE'}) && ($Roomaide_Room{$curr_rm}<1)) {
	print "Must be user level $AXLEVELS{$CONFIG{'AXLEVEL_AIDE'}} ";
	print "or the room aide to edit a room.\n\n";
	print "CR $curr_rm RR $Roomaide_Room{$curr_rm}\n\n";
	return;
    }

    if ($curr_rm <= 3) {
	print "Can't edit Lobby>, Mail>, or Aide>.\n\n";
	return;
    }

    print "Edit this room? (Y/N) ";
    return unless (&yesno);

    &enter_btmp("[Edit Room]");

    my ($roomname, $postax, $enterax, $private, $anon, $network, 
	$editor, $maxallow, $expire, $desc, $unzap, $qws) = 
	    &get_room_opts($curr_rm);

#    print STDERR "Updating room $roomname with number $curr_rm\ndays=$days\nmsgs=$msgs\nflags=$flags\nfloor=$floor\n" if ($DEBUG_ROOM);
	
    &do_sth ( qq(update cit_rooms set roomname='$roomname',
		 postax=$postax, enterax=$enterax, private=$private,
		 anon=$anon, network=$network, editor=$editor,
		 maxallow=$maxallow, expire=$expire where
		 roomnum=$curr_rm));

    if ($unzap==1) {
	&do_sth ( qq(delete from cit_flags
		     where type=$CONFIG{'TYPE_ZA'}
		     and roomnum=$curr_rm));
# to make this work "right":
# for those who had it zapped, you'll want to set lastseen=hir
# but for those who were reading it, dont' fuck with 'em
#	&do_sth ( qq(update cit_flags
#		     set 
#		     where type=$CONFIG{'TYPE_ZA'}
#		     and roomnum=$curr_rm));
    }

    $roomname=~ s{\\}{}g;
    $Room_Names{$curr_rm}=$roomname;

    &cit_alog ($eternal, "edited room $roomname ($curr_rm)");

    return;
}

#===========================================================================
# sub isroom
# used by edit room to make sure the roomname doesn't exist
#===========================================================================
sub isroom {
    my ($roomname) = @_;
#    my %allrooms = &return_room_list;
    foreach $x (keys %Room_Names) {
	return 1 if ($roomname =~ /^$Room_Names{$x}$/i);
    }
    return 0;
}

#===========================================================================
# sub list_known_rooms, print a list of known rooms
#===========================================================================
sub list_known_rooms {
    
    my @unread_rooms;
    my @read_rooms;

    my %msarray   = &new_msg_count;

    foreach my $x (sort { $a <=> $b } keys %Room_Names) {
	my $return = &allowed_in_room($x);

	next unless ($return>0);
	
	unless ($Zapped_Room{$x}) {

	    if ($msarray{"$x"} > $Lastseen_Room{$x}) {
		push @unread_rooms, $Room_Names{$x};
	    } else {
		push @read_rooms, $Room_Names{$x};
	    }
	}
    }

    if (@unread_rooms) {
	print "   Rooms with unread messages:\n"; 
	return if (&inclinecount(1));
	return if (&room_wrap(@unread_rooms));
    }

    if (@read_rooms) {
	print "\n   No unseen messages in:\n";
	return if (&inclinecount(2));
	return if (&room_wrap(@read_rooms));
    }

    print "\n"; 
    return;
}

#===========================================================================
# sub list_zapped_rooms ........ print a list of zapped rooms
#===========================================================================
sub list_zapped_rooms {
    my ($eternal) = @_;
    my @zapped;
    foreach $x (sort {$a <=> $b} keys %Zapped_Room) {
	push @zapped, $Room_Names{$x};
    }

    if (@zapped) {
	print "\n\n   Forgotten public rooms:\n"; 
	return if(&inclinecount(1));
	return if (&room_wrap(@zapped));
    }

    return;
}

#===========================================================================
# sub zap room, allow the user to zap a room
#===========================================================================
sub zap_room {
    my ($curr_rm, $eternal, $axlevel) = @_;

    if (($CONFIG{'FEATURE_AIDE_ZAP'}<1) && ($axlevel >= $CONFIG{'AXLEVEL_AIDE'})) {
	print "Aides can't zap rooms.\n";
	return;
    }

    if ($curr_rm <= 3) {
	print "Can't zap Lobby or Mail.\n";
	return;
    }

    print "Zap room \"$Room_Names{$curr_rm}\"? (Y/N) ";
    return if (!&yesno);

    # since you are in the room we will ASSume that it cannot 
    # already be zapped and forgo the check.

#    print STDERR "Inserting new zapped record user $eternal room $curr_rm\n"
#	if ($DEBUG);

    &do_sth ( qq(insert into cit_flags values 
		 ($CONFIG{'TYPE_ZA'}, $eternal, $curr_rm, 1)));

    # update the "online" zapped list.
    $Zapped_Room{$curr_rm}=1;

    # customizable option to delete their invitation if there was one.
    if ($CONFIG{'FEATURE_KICKOUT_ZAP'}>0) {
	&do_sth ( qq(delete from cit_flags where
		     type=$CONFIG{'TYPE_PR'} and 
		     eternal=$eternal and
		     roomnum=$curr_rm));  
	$Private_Room{$curr_rm}=0;
    }
}

#===========================================================================
# sub invite_user, invite a user into a private room
#===========================================================================
sub invite_user {
    my ($curr_rm) = @_;

    if ($Room_Flags{"${curr_rm}.private"}<1) {
	print "This room is not private.\n";
	return;
    }

    print "Invite user: ";
    my $whoto = &getline($CONFIG{'DEFAULT_HANDLEMAX'});
    return if (!$whoto); #they hit enter.

    #sql_is_user returns handle,eternal; take the eternal
    #or fail and return

    my ($handle,$reternal) = &sql_is_user($whoto);
    if ($reternal<0) {
	print "No such user.\n";
	return;
    }

    print "Invite user $handle ($reternal) to $Room_Names{$curr_rm}? ";
    if (&yesno) {
	&do_sth ( qq(delete from cit_flags where
		     type=$CONFIG{'TYPE_PR'} and
		     eternal=$reternal and
		     roomnum=$curr_rm));
	
	&do_sth ( qq(insert into cit_flags (type, eternal, roomnum, value)
		     values
		     ($CONFIG{'TYPE_PR'}, $reternal, $curr_rm, 1)));

	&cit_alog ($eternal, "invited user $handle ($reternal) to $Room_Names{$curr_rm}");
    }

    return;
}

#===========================================================================
# sub kickout_user, uninvite a user into a private room
#===========================================================================
sub kickout_user {
    my ($curr_rm) = @_;

    if ($Room_Flags{"${curr_rm}.private"}<1) {
	print "This room is not private.\n";
	return;
    }

    print "Kick out user: ";
    my $whoto = &getline($CONFIG{'DEFAULT_HANDLEMAX'});
    return if (!$whoto); #they hit enter.

    #sql_is_user returns handle,eternal; take the eternal
    #or fail and return

    my ($handle,$reternal) = &sql_is_user($whoto);
    if ($reternal<0) {
	print "No such user.\n";
	return;
    }

    print "Kick out user $handle from $Room_Names{$curr_rm}? ";
    if (&yesno) {
	&do_sth ( qq(delete from cit_flags where
		     type=$CONFIG{'TYPE_PR'} and
		     eternal=$eternal and
		     roomnum=$curr_rm));
	&cit_alog ($eternal, "kicked out user $handle ($reternal) from $Room_Names{$curr_rm}");
    }

    return;
}

#===========================================================================
# sub who_knows_room, see a list of who "knows" the room.
# generally for private rooms but will show users who haven't zapped
# a public room too
#===========================================================================
sub who_knows_room {

    my ($curr_rm) = @_;
    my $sth; my $count=0;

    #for a private room, you want those who have a private flag
    #(which accounts for regular users who haven't zapped it)
    #plus aides who haven't zapped it.

    #for a public room, you just want those who haven't zapped it.
    #aide is a special case because it's not private, just restricted.
    #-- well maybe we need to fix up enterax/postax and use it for 
    #   aide room access.

    # we also have enterax level rooms like aide.

    if ($Room_Flags{"${curr_rm}.private"}>0) {
	$sth = &do_sth ( qq(select distinct
			    cit_flags.value,cit_users.handle
			    from cit_users,cit_flags
			    where 
			    cit_flags.eternal=cit_users.eternal AND
			    cit_flags.roomnum=$curr_rm 

			    AND (cit_flags.type=$CONFIG{'TYPE_PR'}
				 OR cit_flags.type=$CONFIG{'TYPE_RI'})

			    order by cit_users.handle));

	while ( my ($flag, $handle) = $sth->fetchrow ) {
	    if ($flag) {
		print "$handle\n"; return if (&inclinecount(1));
		$count++;
	    }
	}
    } else {
	$sth = &do_sth ( qq(select cit_flags.value,
			    cit_users.handle,
			    cit_users.axlevel
			       from cit_users 
			       LEFT JOIN cit_flags on
			       cit_flags.type=$CONFIG{'TYPE_ZA'} AND
			       cit_flags.eternal=cit_users.eternal AND
			       cit_flags.roomnum=$curr_rm 
			       ORDER BY cit_users.handle));
	while ( my ($flag, $handle, $ax) = $sth->fetchrow ) {
	    unless ($flag) {
		next if ($curr_rm==3 && $ax < $CONFIG{'AXLEVEL_AIDE'});
		print "$handle\n"; return if &inclinecount(1);
		$count++;
	    }
	}
    }
    print "\n$count users (plus the aides...).\n";
}

#===========================================================================
# sub print_room_desc... print the room description, duh
#===========================================================================
sub print_room_desc {
    my ($curr_rm) = @_;

    my %a = &get_roomaide_list($curr_rm);
    my $count=0;

    print "Roomaides:\n";
    foreach my $x (sort keys %a) {
	print "\t$a{$x}\n";
	$count++;
    } 
    if ($count==0) {
	print "\tNone.\n";
    }

    my $sth = &do_sth ( qq(select description from cit_rooms
			   where roomnum=$curr_rm));
    my ($description) = $sth->fetchrow;
    $sth->finish;
    $description=decode_base64($description);
    print "\nDescription:\n\n";
    if (length($description)>1) {
	print "$description\n";
    } else {
	print "\tNone.\n";
    }
}

#===========================================================================
# sub room_wrap
# "wrap" the list of rooms for known room list to user's screen width
#===========================================================================
sub room_wrap {
    my (@array) = @_;
    
    my $charcount=0; my $test=0;

    my $line="$array[0]>  "; 

    foreach $x (1..$#array) {
	$test = $charcount + length($array[$x]) + 5;
	if ($test > $USER{'screenwidth'}) {
	    $line = $line . "\n";
	    print $line; return(1) if (&inclinecount(1));
	    $line = "$array[$x]>  ";
	    $charcount=length($line); 
	} else {
	    $line = $line . "$array[$x]>  ";
	    $charcount = length($line);
	}
    }
    $line = $line . "\n";
    return(1) if &inclinecount(1);
    print "$line";
    return;
}
    
#===========================================================================
# get_room_opts, prompt the user for room parameters (create or editroom)
#===========================================================================
sub get_room_opts {
    my ($curr_rm) = @_;

# display current settings.. or if creating a room for the first time, we'll come up with a set of defaults.

    my $cur_anon;
    my $cur_private;
    my $cur_editor;
    my $cur_postax;
    my $cur_enterax;
    my $cur_roomname;
    my $cur_maxallow;
    my $cur_expire;
    my $cur_network=0;

    if ($curr_rm == 0) {
	$cur_anon=0;
	$cur_private=0;
	$cur_editor=$CONFIG{'FEATURE_ENABLE_EDITOR'};
	$cur_postax=$CONFIG{'AXLEVEL_NORM'};
	$cur_enterax=$CONFIG{'AXLEVEL_NEW'};
	$cur_expire=$CONFIG{'DEFAULT_MSGS_DAYS'};
	$cur_maxallow=$CONFIG{'DEFAULT_MSGS_MAX'};
	my %cur_roomaides;

      ROOMNAME: 	print "Name of new room: ";
	$cur_roomname=&getline(50);
	if (length($cur_roomname)>0) {
	    $cur_roomname =~ s/[\000-\037\177-\377]//g; #lose nonprintables
	    if (&isroom($cur_roomname)) {
		print "That room name is already in use. ",
		"Please choose another.\n";
		goto ROOMNAME;
	    } 
	} else {
	    return ($cur_roomname, $cur_postax, $cur_enterax, $cur_private, $cur_anon,
		    $cur_network, $cur_editor, $cur_maxallow, $cur_expire, 0, 1);
	}

    } else {
	$cur_anon=$Room_Flags{"$curr_rm.anon"};
	$cur_editor=$Room_Flags{"$curr_rm.editor"};
	$cur_private=$Room_Flags{"$curr_rm.private"};
	$cur_postax=$Room_Flags{"$curr_rm.postax"};
	$cur_enterax=$Room_Flags{"$curr_rm.enterax"};
	$cur_roomname=$Room_Names{$curr_rm};
	$cur_expire=$Room_Flags{"$curr_rm.expire"};
	$cur_maxallow=$Room_Flags{"$curr_rm.maxallow"};
	%cur_roomaides=&get_roomaide_list;
    }	

	
    my $new_anon=$cur_anon;
    my $new_editor=$cur_editor;
    my $new_private=$cur_private;
    my $new_postax=$cur_postax;
    my $new_enterax=$cur_enterax;
    my $new_roomname=$cur_roomname;
    my $new_expire=$cur_expire;
    my $new_maxallow=$cur_maxallow;
    my $new_unzap=0;
    my %new_roomaides=%cur_roomaides;

    PRINT: while (1) {
	system "clear";
	my $tmp = $new_roomname;
	$tmp =~ s{\\}{}g;
	print "Editing Room $tmp ($curr_rm)\n\n";
	print "(1) Room Name.                    $tmp\n";

	if ($new_unzap==1) {
	    print "                                   (Will unzap the room for everyone if you save the changes.)\n";
	}

	print "(2) Room Type.                    ";
	if ($new_private == 1) {
	    print "Private\n";
	} else {
	    print "Public\n";
	}
	print "(3) Axlevel to post.              $AXLEVELS{$new_postax} ($new_postax)\n";
	
	print "(4) Axlevel to read.              $AXLEVELS{$new_enterax} ($new_enterax)\n";
	
	print "(5) Anonymous status.             ";
	if ($new_anon == 1) {
	    print "Optional\n";
	} elsif ($new_anon == 2) {
	    print "Enforced\n";
	} else {
	    print "None\n";
	}
	
	print "(6) Allow editor.                 ";
	if ($new_editor == 1) {
	    print "Yes\n";
	} else {
	    print "No\n";
	}
	
	print "(7) Max messages room.            $new_maxallow\n";
	print "(8) Days to retain old posts.     $new_expire\n";
	
	print "(a) Add room aides.\n";
	print "(d) Delete room aides.\n";
	my $count=0;
	foreach my $x (sort keys %new_roomaides) {
	    print "\tCurrent Roomaide: $new_roomaides{$x} (#$x)\n";
	    $count++;
	} 
	if ($count==0) {
	    print "\tNo roomaides.\n";
	}

	print "\n\nEnter option to change, \"S\" to exit and save changes, \"Q\" to exit and discard changes: ";
	$option = &retkey('1', '2', '3', '4', '5', '6', '7', '8', 'a', 'd', 's', 'q');
	print "$option\n";
	
	if ($option eq '1') {
	  NEWNAME: 	print "New name [$new_roomname]: ";
	    $new_roomname=&getline($CONFIG{'DEFAULT_ROOMNAMEMAX'});
	    if (length($new_roomname)>0) {
		$new_roomname =~ s/[\000-\037\177-\377]//g; #lose nonprintables
		if (&isroom($new_roomname)) {
		    print "That room name is already in use. ",
		    "Please choose another.\n";
		    goto NEWNAME;
		} 
		print "You've changed the name of the room.\nDo you want to unzap the room for everyone? (Y)es, (N)o: ";
		if (&yesno) {
		    $new_unzap=1;
		}
	    } else {
		$new_roomname=$cur_roomname;
	    }
	    $new_roomname = quotemeta($new_roomname);
	} elsif ($option eq '2') {
	    print "Room type (P)ublic, (I)nvite Only (private): ";
	    my $poption = &retkey('p', 'i');
	    if ($poption eq "p") {
		print "Public\n";
		$new_private=0;
	    } elsif ($poption eq 'i') {
		print "Invite\n";
		$new_private=1;
	    }
#	    elsif ($poption eq "g") {
#		print "Guessname\n";
#		$new_private=2;
#	    }	
	} elsif ($option eq '3') {
	  POSTAX: print "Posting type (A)ll, (#)Axlevel [? to list]: ";
	    my $poption = &retkey('a', '0', '1', '2', '3', '4', '5', '?');
	    if ($poption eq "a") {
		print "All\n";
		$postax=$CONFIG{'DEFAULT_AX_VALIDUSER'};
	    } elsif ($poption eq '?') {
		print "List\n";
		foreach my $x (0..5) {
		    print "$x, $AXLEVELS{$x}\n";
		}
		goto POSTAX;
	    } else {
		print "Selected axlevel $poption ($AXLEVELS{$poption}\n";
		$new_postax=$poption;
	    }
	} elsif ($option eq '4') {
	  ENTERAX: print "Room visible to (A)ll, (#)Axlevel [? to list]: ";
	    my $poption = &retkey('a', '0', '1', '2', '3', '4', '5', '?');
	    if ($poption eq "a") {
		print "All\n";
		$new_enterax=1;
	    } elsif ($poption eq '?') {
		print "List\n";
		foreach $x (0..7) {
		    print "$x, $AXLEVELS{$x}\n";
		}
		goto ENTERAX;
	    } else {
		print "Selected axlevel $poption ($AXLEVELS{$poption}\n";
		$new_postax=$poption;
	    }
	} elsif ($option eq '5') {
	    print "Anonymous type (N)one, (O)ptional, Enforced (A)nonymous: ";
	    my $poption = &retkey('n', 'o', 'a');
	    if ($poption eq "n") {
		print "None\n";
		$new_anon=0;
	    } elsif ($poption eq "o") {
		print "Anon. Optional\n";
		$new_anon=1;
	    } else { # ($poption eq "a")
		print "Anon. Enforced\n";
		$new_anon=2;
	    }	
	} elsif ($option eq '6') {
	    print "Allow editor (Y)es, (N)o: ";
	    if (&yesno) {
		$new_editor=1;
	    }
	} elsif ($option eq '7') {
	    print "Messages to allow in room, 0 for unlimited [$new_maxallow]: ";
	    my $tmp = &getline(3);
	    $tmp *= 1;
	    if ($tmp > 0) {
		$new_maxallow=$tmp;
	    }
	} elsif ($option eq '8') {
	    print "Days to retain old posts, 0 for unlimited [$new_expire]: ";
	    my $tmp = &getline(3);
	    $tmp *= 1;
	    if ($tmp > 0) {
		$new_expire = $tmp;
	    }
	} elsif ($option eq 'a') {
	    print "Add Roomaide (User Name): ";
	    my ($nh, $ne) = &sql_is_user(&getline($CONFIG{'DEFAULT_HANDLEMAX'}));
	    if ($ne < 0) {
		print "Couldn't find user. Press any key to continue.\n";
		&getkey;
	    } else {
		$new_roomaides{$ne}=$nh;
	    }
	} elsif ($option eq 'd') {
	    print "Delete Roomaide (User Name): ";
	    my ($nh, $ne) = &sql_is_user(&getline($CONFIG{'DEFAULT_HANDLEMAX'}));
	    if ($ne < 0) {
		print "Couldn't find user. Press any key to continue.\n";
		&getkey;
	    } else {
		delete $new_roomaides{$ne};
	    }
	} elsif ($option eq 'q') {
	    print "Quit without saving? (Y)es, (N)o: ";
	    if (&yesno) {
		return ($cur_roomname, $cur_postax, $cur_enterax, $cur_private, $cur_anon,
			$cur_network, $cur_editor, $cur_maxallow, $cur_expire, 0, 1);
	    }
	} elsif ($option eq 's') {
	    print "Save changes? (Y)es, (N)o: ";
	    if (&yesno) {
		&set_roomaide_list($curr_rm,%new_roomaides);
		return ($new_roomname, $new_postax, $new_enterax, $new_private, $new_anon,
			$cur_network, $new_editor, $new_maxallow, $new_expire, $new_unzap, 0);
	    }
	} else {
	    next PRINT;
	}
    }
}
	    
#    my $network=0;
#    if ($CONFIG{'FEATURE_NETWORKED'}>0) {
#	print "Network room (Y)es, (N)o: ";
#	if (&yesno) {
#	    $network=1;
#	}
#    } 

#===========================================================================
# sub new_msg_count
# return a list of rooms with new messages, for use in known rooms listing
#===========================================================================
sub new_msg_count {

#    print "Nmc select start $eternal\n";

    my $sth = &do_sth ( qq(select msgnum,roomnum
			   from cit_messages 
			   where roomnum!=2
			   and deleted!=1));

    while ( my ($ms,$rn) = $sth->fetchrow) {
	$narray{"$rn"}=$ms if ($ms > $narray{"$rn"});
    }

    $sth->finish;

    my $sth = &do_sth ( qq(select msgnum,roomnum
			   from cit_messages 
			   where roomnum=2
			   and (recipient=$eternal or handle=$eternal)
			   and deleted!=1));

    while ( my ($ms,$rn) = $sth->fetchrow) {
	$narray{"$rn"}=$ms if ($ms > $narray{"$rn"});
    }
    
    $sth->finish;

    return (%narray);

}

#===========================================================================
# sub get_all_room_flags
# returns an array of flags for rooms.
# Room_Flags  ${rm}.postax , enterax, private, anon, editor
# Room_Numbers key name = number
# Room_Names key number = name
#===========================================================================
sub get_all_room_flags {
    my $sth = &do_sth ( qq(select roomnum, roomname, postax, enterax, private, anon, editor, maxallow, expire
			   from cit_rooms));

    undef %Room_Numbers; undef %Room_Names;
    while ( my ($rm, $name, $po, $e, $pr, $an, $edit, $ma, $ex) = $sth->fetchrow ) {
	$Room_Numbers{"$name"}      ="$rm";
	$Room_Names{"${rm}"}        ="$name";

	$Room_Flags{"${rm}.postax"} ="$po";
	$Room_Flags{"${rm}.enterax"}="$e";
	$Room_Flags{"${rm}.private"}="$pr";
	$Room_Flags{"${rm}.anon"}   ="$an";
	$Room_Flags{"${rm}.editor"} ="$edit";
	$Room_Flags{"${rm}.maxallow"} ="$ma";
	$Room_Flags{"${rm}.expire"}   ="$ex";
    }

    $sth->finish;
}

#===========================================================================
# sub gotoroom
# used by <G>oto and .<G>oto-- actually does the work
# args curr_rm (where to go)
#
# we assume that if we get here that the permissions checks have passed
# returns roomname, lowest new message
#===========================================================================
sub gotoroom {
    my ($curr_rm) = @_;

    unless ($Room_Names{$curr_rm}) {
	print "Error, gotoroom, room $curr_rm has no name?\n";
	$curr_rm=1;
    }

    # figure out how many new in here. 
    my ($tot, $new) = &msg_nums ($curr_rm);

    if ($tot == 1) {
	print "$Room_Names{$curr_rm} ($tot message, $new new)\n";
    } else {
	print "$Room_Names{$curr_rm} ($tot messages, $new new)\n";
    }

    # if the room had been prior zapped, now it's not zapped.
    if ($Zapped_Room{$curr_rm}>0) {
	&do_sth ( qq(delete from cit_flags 
		     where type=$CONFIG{'TYPE_ZA'}
		     and   eternal=$eternal
		     and   roomnum=$curr_rm));
	
	delete $Zapped_Room{$curr_rm};
    }

    # also unset skipping value for this room, since we're here now
    delete $Skipping_Room{$curr_rm};

    # print the room description if it has changed since lastseen
    my $sth = &do_sth( qq(select desctime from cit_rooms
			  where roomnum=$curr_rm));
    my ($desctime) = $sth->fetchrow;
#    print "desctime $desctime lscr $Lastseen_Room{$curr_rm}\n";
    &print_room_desc($curr_rm) if ($Lastseen_Room{$curr_rm} < $desctime);
    $sth->finish;

    my @end_hir = &msg_list($curr_rm);
    return ($Lastseen_Room{$curr_rm},$end_hir[$#end_hir]);
}

#===========================================================================
# sub jump
# returns room num of the room they wish to visit; 
# or 1 (to go to lobby) if they bail or type in a nonexistant room.
#===========================================================================
sub jump {
    my ($curr_rm) = @_;

    print "Room name: ";
    my $room = &getline($CONFIG{'DEFAULT_ROOMNAMEMAX'});
    return $curr_rm if (!$room); # whatever they were in before

#    $room =~ s{\'}{\\\'}g;

    $room=quotemeta($room);

    foreach $x (sort numerically keys %Room_Names) {
	if ($Room_Names{$x} =~ /$room/i) {
	    return $x if (&allowed_in_room($x) > 0);
	}
    } 

    # either the room wasn't found-- or the user was denied.
    print "Room not found.\n";
    return 1; # going to lobby.
}

#===========================================================================
# sub gotonext
# determine which room has unread messages and whether we're allowed
# to go to that particular room
#===========================================================================
sub gotonext {
    my ($eternal, $axlevel) = @_;

# march mode...
# is it sufficient to say, don't goto room (X) if X<$curr_rm?
# also... we could offer the ability to "gotonext" in order of room number or name

    # pre-seed max msgnums
    my %marry = &msgs_room;

    foreach my $x (sort { $a <=> $b } keys %Room_Names) {
#	print STDERR "Checking $Room_Names{$x} ... $marry{$x} .... ls $Lastseen_Room{$x}\n";
	next if ($Zapped_Room{$x}>0);     # don't go if zapped
	next if ($Skipping_Room{$x}>0);   # don't go if skipping

	next unless (&allowed_in_room($x) > 0 );

	return $x if ($marry{$x} > $Lastseen_Room{$x});

	# else, go back and try again.
    }   

    # if we fall through, we didn't find any non-zapped, non-skipped
    # non-private rooms with new messages. So, see if there's anything 
    # in skipping to goto. if so, we go to the first room in skipping 

    if (scalar keys %Skipping_Room) {
	print "*** You have skipped rooms.\n";
#	foreach $x (sort keys %Skipping_Room) {
#	    print "SKIP $x $Skipping_Room{$x}\n";
#	}

	undef %Skipping_Room;
	return 1;
    }

#	foreach my $x (sort keys %Skipping_Room) { 
#	    if ($Skipping_Room{$x}>0) {
#		print "*** You have skipped rooms.\n";
#		$Skipping_Room{$x}=0;
#		return $x if (&allowed_in_room($x) > 0);
#	    }
#	}

    # hmm still here? no new that meet ANY criteria. goto Lobby.
    return 1; 
}

#===========================================================================
# sub update_lastseen.... 
#
# some notes...
# make messages old in current room
# skipping should make last_msg_read = ls
# goto should make hir = ls
# abandon should make last_msg_read = original new msg.
#===========================================================================
sub update_lastseen {
    my ($x, $hir) = @_;

    $hir=0 unless $hir>0;


    my $sth = &do_sth( qq(select count(*) from cit_flags
			  where roomnum=$x
			  and eternal=$eternal
			  and type=$CONFIG{'TYPE_LS'}));
    my ($dls) = $sth->fetchrow;
    $sth->finish;

#    print "DEBUG: Update lastseen: $x hir $hir dls $dls\n" if ($DEBUG);

    if ($dls>0) {    
	if ($hir > $dls) {
	    &do_sth ( qq(update cit_flags 
			 set value=$hir
			 where type=$CONFIG{'TYPE_LS'} and
			 eternal=$eternal and
			 roomnum=$x));
	}
    } else {
	&do_sth ( qq(insert into cit_flags 
		     (type, eternal, roomnum, value) values
		     ($CONFIG{'TYPE_LS'}, $eternal, $x, $hir)));
    }
    $Lastseen_Room{$x}=$hir;
}

#===========================================================================
# sub allowed_in_room, for a given user and curr_rm check to see if they
# are allowed in
#===========================================================================
sub allowed_in_room {
    my ($x) = @_;

    # first test. Aides see everything.
    return 1 if ($USER{'axlevel'} >= $CONFIG{'AXLEVEL_AIDE'});

    # next easiest test. no non-aides in aide room.
    if ($x==3) {
	if ($USER{'axlevel'} < $CONFIG{'AXLEVEL_AIDE'}) {
	    return -1;
	} else {
	    return 1;
	}
    }
    # check for private room permission
    if ($Room_Flags{"${x}.private"} > 0 ) {
	if ($Private_Room{$x} > 0) {
	    return 1;
	} else {
	    return -1;
	}
    }

    if ($Room_Flags{"${x}.enterax"} > 0 ) {
	if ($USER{'axlevel'} >= $Room_Flags{"${x}.enterax"}) {
	    return 1 ;
	} else {
	    return -1;
	}
    }

    # must have passed all tests.
    return 1;
}

#===========================================================================
# return an assoc array of eternal,handle of roomaides of a curr_rm
#===========================================================================
sub get_roomaide_list {
    my ($curr_rm) = @_;

    my $sth = &do_sth( qq(select cit_flags.eternal,cit_users.handle 
			  from cit_flags,cit_users
			  where cit_flags.roomnum=$curr_rm
			  and type=$CONFIG{'TYPE_RI'}
			  and cit_flags.eternal=cit_users.eternal));

    my %a;
    while (my ($eternal,$handle) = $sth->fetchrow) {
	$a{$eternal}=$handle;
    }

    $sth->finish;
    return %a;
}

#===========================================================================
# take an assoc array of eternal,handle of roomaides of a curr_rm
#===========================================================================
sub set_roomaide_list {
    my ($curr_rm, %roomaides) = @_;

    &do_sth( qq(delete from cit_flags
		where cit_flags.roomnum=$curr_rm
		and type=$CONFIG{'TYPE_RI'}));

    foreach my $x (keys %roomaides) {
	&do_sth( qq(insert into cit_flags 
		    (type, eternal, roomnum, value) values
		    ($CONFIG{'TYPE_RI'}, $x, $curr_rm, 1)));
    }
}

#===========================================================================
# enter the room description....
#===========================================================================
sub enter_room_description {

    my ($curr_rm) = @_;

    my $sth = &do_sth ( qq(select description from cit_rooms
			   where roomnum=$curr_rm));
    my ($description) = $sth->fetchrow;
    $sth->finish;

    $description=decode_base64($description);

    print "--------------- Current description ----------------\n";
    print "$description\n";
    print "----------------------------------------------------\n";

    print "Modify (y/n)? ";
    return unless &yesno;

    if ( ($childpid=fork()) == 0) {
	&unset_terminal;

	unlink ("$mytmpfile"); #in case it's still hanging around
	unless (open (TMP,">$mytmpfile")) {
	    print "Can't seem to copy desc. from database for editing.\n\n";
	    &set_terminal;
	    return;
	} else {
#	    print "old desc $description\n";
	    print TMP "$description";
	    close (TMP);
	}
#	print "Pid saved, $childpid -- Pid to open $$\n";
#	print "cmd: $CONFIG{'BBSDIR'}/$CONFIG{'PROG_EDITOR'} $mytmpfile\n\n";
	exec("$CONFIG{'BBSDIR'}/$CONFIG{'PROG_EDITOR'} $mytmpfile");
	exit ($?);
    } 

    waitpid($childpid,0);
    &set_terminal;

    if ($?>0) { # should be 0
	print "Ok, not saving, or couldn't run the editor.\n";
	return;
    }

    my $string;
    # when it comes back, snarf it's tmp file turd into $string.
    if (open (TURD, "$mytmpfile")) {
	print "Saving room description.\n";
	#slurp the whole file-- from the Perl FAQ.
	$string = do { local $/; <TURD> };
	close (TURD);
	unlink "$mytmpfile";
    } else {
	print "Saving empty room description anyway.\n";
	$string = '';
    }

    $string=encode_base64($string);
    &do_sth ( qq(update cit_rooms
		 set description='$string'
		 where roomnum=$curr_rm));
    
    &cit_alog ($eternal, "modified room desc for $Room_Names{$curr_rm} (#$curr_rm)");
    unlink ("$mytmpfile"); #in case it's still hanging around
    return;
}

sub numerically { $a <=> $b; }

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


