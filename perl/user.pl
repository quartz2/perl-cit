#!/usr/local/bin/perl

# login_user.pl
# Routines pertaining to login, new user, password changing, user config.
 
# Part of Citadel/Quux 
# David Pirmann (pirmann@quuxuum.org)
# 6/18/1998

#-----------------------------------------------------------------------------
# sub enter_name................ reads handle from kbd
# args: none
# returns: the value of is_user
# (handle if it exists, -1 if not)
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub enter_name {
#   print STDERR "enter_name: no args\n" if ($DEBUG);

    my $done, $handle;
    while (!$done) {
	print "\rEnter your handle: ";	
	$handle = &getline($CONFIG{'DEFAULT_HANDLEMAX'});

	$done++ if ($handle);
    }

    # allow the user to escape
    if ( $handle eq "off" || $handle eq "logoff") {
#	print STDERR "enter_name: user chose to log off\n" if ($DEBUG);
	&user_terminate($CONFIG{'UL_OFF'});
    }
    
    # check to see if the entered handle exists. if it does, the &is_user 
    # subroutine will return the handle with the "proper" capitalization 
    # which we will remember and use throughout.

    my $tmp = (&sql_is_user($handle))[0]; # just take the handle portion

#    print STDERR "enter_name: returning is_user handle $handle\n"
#	if ($DEBUG);
    return ($tmp, $handle);
}

#-----------------------------------------------------------------------------
# sub enter_password................ reads password from kbd and checks it
# args: handle
# returns: 0 if it's ok, 1 if not
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub enter_password {
    my ($handle) = @_;
#    print STDERR "enter_passwd: args handle $handle\n" if ($DEBUG);

    print "\rPlease enter your password: ";
    my $pwtest = &getline (-$CONFIG{'DEFAULT_PASSWDMAX'});
	
    if (&sql_check_passwd($handle,$pwtest)) {
	# return value of 0 means pw ok
#	print "Returned good!\n";
	return 0;
    } 

    # if we didn't return up there, the user failed so ask again.
	
    print "\nSorry, the password you've entered is incorrect.\n\n";

    if (++$failures >= 3) {
	print "Too many attempts. Goodbye\n";
	&logoff($CONFIG{'UL_BADPW'});
    }

    return 1;
}

#-----------------------------------------------------------------------------
# sub do_new_user............... double check if the user wants to login
# as a new user. gather up the new user's password, and call the insert to db.
# args: handle
# returns: -1 if they choose not to login or if handle was invalid
# returns ($handle, $eternal) if everything ok
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub do_new_user {
    my ($handle) = @_;
#    print STDERR "do_new_user: args handle $handle\n" if ($DEBUG);

    print "\nThe handle you entered was not found.\n";
    print "Enter as a new user? (y/n) ";

    return (-1, -1) unless (&yesno); # the No answer.

    # no new users unpleasantness

    if ( -f ".nonew" ) {
	&formout($CONFIG{'FILE_NONEW'});
	sleep 1; 
	&user_terminate($CONFIG{'UL_NONEW'});
    }

    # now lets validate the handle....

    # strip any non-printable characters from handle.
    $handle =~ s/[\000-\037\177-\377]//g; #lose nonprintables

    return (-1, -1) if (&validate_handle($handle));

    # prohib_from_hosts goes here if we think it's necessary

    &formout($CONFIG{'FILE_NEWUSER'}); 
    print "Do you accept the above conditions? [Y/N] ";
    &user_terminate($CONFIG{'UL_OFF'}) unless (&yesno);

    print "\nThe handle you entered is \'$handle\'.\n";
    print "If this is not the handle you wish to use on the system, press N now.\n";
    print "\nDo you still want to log in? ";

    &user_terminate($CONFIG{'UL_OFF'}) unless (&yesno);

    # prompt for a password and encrypt it, then insert it and return eternal
    &sql_insert_newuser (quotemeta($handle), &set_passwd ($handle, 0));

    &cit_alog (0, "new user created: $handle");

#    print STDERR "do_new_user: returning handle $handle eternal $eternal\n"
#	if ($DEBUG);

    return ($handle);

} 

#-----------------------------------------------------------------------------
# sub set_passwd ................ allow the user to change password,
# or for first time users, get the new password
# args: handle, timescalled
# returns: -1 if success for existing user, crypted_pw if success for new user
# checked 6/21/2002 pirmann
# handle is used in the salt. timescalled ensures a new user
# doesn't try to skip entering the password.
#-------------------------------------------------------------------------
sub set_passwd {

    my ($handle, $timescalled) = @_;

    &formout ($CONFIG{'FILE_CHANGEPW'}) unless ($USER{'expert'});

  GETPW: 

    print "\nPlease enter a password: ";
    my $pwread = &getline(-$CONFIG{'DEFAULT_PASSWDMAX'});

    #if an existing user hits return, just exit routine.
    if (! length($pwread) && ($USER{'timescalled'} > 0)) {
	print "Okay, so we won't change it.\n";
	return (-1);
    }

    # new users can't just hit return.
    if (! length($pwread) ) {
	print "Password must be of non-zero length.\n";
	goto GETPW;
    }
	  
    printf("Please enter it again: ");
    $pwtest = &getline(-$CONFIG{'DEFAULT_PASSWDMAX'});
    
    if ($pwread ne $pwtest) {
	print "The passwords you typed didn't match.  Please try again";
	if ($timescalled > 0) {
	    print ",\nor press return to exit without changing your password.\n\n";
	} else {
	    print ".\n\n";
	}
	goto GETPW;
    }
    
    $crypted_pw = &encrypt_passwd($handle,$pwread);

    if ($USER{'timescalled'}>0) { 
	# for "old" users lets update the db now
	&sql_change_pw ($handle, $crypted_pw);
	print "Password changed.\n";

	&cit_alog ($eternal, "changed password");

	return -1;
    } else { 
	# for new users, just return the password we read to new_user 
	# routine and let it do the busywork
	return ($crypted_pw);
    }

    # should never get here.

} 

#-----------------------------------------------------------------------------  
# sub encrypt_passwd
# encrypts the users plaintext password. stolen from an ora perl book i think.
#-----------------------------------------------------------------------------  
sub encrypt_passwd {
    my($user,$pass)=@_;
    my($nslat,$week,$now,$pert1,$pert2);
    my(@salt_set)=('a'..'z','A'..'Z','0'..'9','.','/');
    $now=time;
    ($pert1,$pert2) = unpack("C2",$user);
    $week = $now / (60*60*24*7) + $pert1 + $pert2;
    $nsalt = $salt_set[$week % 64] . $salt_set[$now %64];
    return crypt($pass,$nsalt);
}

#-----------------------------------------------------------------------------  
# register a user with name and address, at the first call.
#-----------------------------------------------------------------------------  
sub set_registration {
    my %REGIS;

    &enter_btmp ("[Registration]");

    &formout ($CONFIG{'FILE_REGISTER'}) ;

    while (!$done) {

	print "\n";
      REALNAME: 
	
	print "FULL REAL name: ";
	$REGIS{'name'} = &getline(50);
	
	if (! $REGIS{'name'} ) {
	    print "You don't have a real name?! ";
	    print "Please enter your name.\n";
	    goto REALNAME;
	}
	
	print "Street Address: ";
	$REGIS{'addr'} = &getline(50);
	
	print "City/town: ";
	$REGIS{'city'} = &getline(50);
	
	print "State/Country: ";
	$REGIS{'state'} = &getline(50);
	    
	print "ZIP/Postal code: ";
	$REGIS{'zip'} = &getline(50);
	    
	print "Phone number: ";
	$REGIS{'phone'} = &getline(50);
	
	print "Email address: ";
	$REGIS{'email'} = &getline(50);
	
	print "Web home page (optional): ";
	$REGIS{'url'} = &getline(150);
	
	print "\n";
	
	print "*** You have entered the following:\n";
	
	print "$REGIS{'name'}\n",
	"$REGIS{'addr'}\n",
	"$REGIS{'city'}, $REGIS{'state'}, $REGIS{'zip'}\n",
	"$REGIS{'phone'}\n",
	"$REGIS{'email'}\n";
	"$REGIS{'url'}\n";
	
	print "\nIs this correct (y/n)? ";
	if (&yesno) {
	    print "\n\n*** Thank you for registering!\n\n";
	    $done = 1 ;
	}
    }
    &do_sth ( qq(update cit_users set
		 name="$REGIS{'name'}",
		 addr="$REGIS{'addr'}",
		 city="$REGIS{'city'}",
		 state="$REGIS{'state'}",
		 zip="$REGIS{'zip'}",
		 phone="$REGIS{'phone'}",
		 email="$REGIS{'email'}",
		 url="$REGIS{'url'}",
		 regis=1
		 where eternal=$eternal));

    return;
}
 
#----------------------------------------------------------------------
sub print_login_banner {

    $USER{'timescalled'}++;

    print "\nUser $USER{'handle'} (#$eternal), ",
    "Access level: $AXLEVELS{$USER{'axlevel'}}, ",
    "Call \#$USER{'timescalled'}\n";
    
    my $ltime = localtime($USER{'lastcall'});
    my $ftime = localtime($USER{'firstcall'});
    
    if ($USER{'timescalled'} > 1) {
	print "Last login: $ltime from $USER{'host'}\n";
	my $m = int($USER{'timetoday'}/60);
	my $h = int($m/60); $m = $m - (60*$h);
	print "You have been on ${h}h ${m}m today.\n";
    }
    print "\n";
}


sub validate_handle {
    my ($handle) = @_;
#    print STDERR "validate_handle: $handle\n" if ($DEBUG);

    if ( $handle =~ /^(bbs|new)$/i) {
	print "Sorry, but \"$handle\" is not allowed as a username.\n\n";
	return 1;
    }

    if ($handle =~ /shit|fuck/i) {
	print "Sorry, but \"$handle\" is not allowed as a username.\n\n";
	return 1;
    }

    if (length($handle) <= 1 ) {
	print "Handles must be two letters or longer. Please try again.\n\n";
	return 1;
    }

    &logoff($CONFIG{'UL_OFF'}) if ( $handle =~ /^off|logoff$/i );

    return 0;
}


#-----------------------------------------------------------------------------
# sub is_user....................... finds out if typed handle exists in db
# args: handle
# returns: properly capitalized handle if exists, -1 if it doesn't
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub sql_is_user {
    my ($handle) = @_;
#    print STDERR "is_user: args $handle\n" if ($DEBUG);

    $handle = quotemeta($handle);

    # mysql like is not case-sensitive
    my $sth = &do_sth ( qq(select handle,eternal from cit_users 
			   where handle like '$handle'));

    if ( my ($handle,$eternal) = $sth->fetchrow) {
	return ($handle, $eternal);
    } else {
	return (-1, -1);
    }
}

#-----------------------------------------------------------------------------
# sub change_pw ..................... updates passwd field in database
# args: handle, typed password
# returns: nothing. exits if error.
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub sql_change_pw {
    my ($handle, $pw) = @_;
#    print STDERR "change_pw: args $handle, $pw\n" if ($DEBUG);

    # going to use handle here because for new users we don't have an eternal yet.
    $handle=quotemeta($handle);

    &do_sth ( qq(update cit_users set password='$pw'
		 where handle='$handle'));

}

#-----------------------------------------------------------------------------
# sub insert_newuser................. insert new user info to database
# args: handle, typed password, initial flags
# returns: eternal
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub sql_insert_newuser {
    my ($handle, $pw) = @_;
#    print STDERR "insert_newuser: args $handle, $pw\n" if ($DEBUG);

    my $nowtime = time;

    &do_sth ( qq(lock tables cit_users WRITE));

    &do_sth ( qq(insert into cit_users 
		 (eternal, handle, password, axlevel, perm, lastold,
		  expert, pause, prompt, hide, editor, smartspace,
		  marchmode, screenwidth, screenlength, timelimit,
		  firstcall, lastcall, timescalled, valid, regis,
		  posted, timeonline, timetoday)
		 values (NULL, '$handle', '$pw', 
			 $CONFIG{'DEFAULT_AX_NEWUSER'},
			 $CONFIG{'DEFAULT_USER_PERMANENT'},
			 $CONFIG{'DEFAULT_USER_LASTOLD'}, 
			 $CONFIG{'DEFAULT_USER_EXPERT'}, 
			 $CONFIG{'DEFAULT_USER_PAUSE'},
			 $CONFIG{'DEFAULT_USER_PROMPT'},
			 $CONFIG{'DEFAULT_USER_HIDE'},
			 $CONFIG{'DEFAULT_USER_EDITOR'},
			 $CONFIG{'DEFAULT_USER_SMARTSPACE'},
			 $CONFIG{'DEFAULT_USER_MARCHMODE'},
			 $CONFIG{'DEFAULT_USER_SCREENWIDTH'}, 
			 $CONFIG{'DEFAULT_USER_SCREENLENGTH'},
			 $CONFIG{'DEFAULT_USER_TIMELIMIT'},
			 $nowtime, 0, 0, 0, 0, 0, 0, 0)));

    &do_sth ( qq(unlock tables));

}

#-----------------------------------------------------------------------------
# sub check_passwd........... Match typed to stored password using crypt.
# args: handle, typed password
# returns: 1 if match, 0 if not
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub sql_check_passwd {
    my($handle,$typedpass) = @_;
#    print STDERR "check_passwd: $handle, $typedpass\n" if ($DEBUG);

    $handle=quotemeta($handle);

    my $sth = &do_sth ( qq(select password from cit_users
			   where handle='$handle'));

    my ($dbpw) = $sth->fetchrow;
    my $nsalt = substr ($dbpw, 0, 2);
    my $testpw = crypt($typedpass,$nsalt);

    return 1 if ($dbpw eq $testpw);
    return 0;
}

#-----------------------------------------------------------------------------
# Sub return_eternal........ Fetches the eternal from the database
# args: handle
# returns: eternal or exits.
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub sql_return_eternal {

    $handle=quotemeta($handle);

    my $sth = &do_sth ( qq(select eternal from cit_users
			   where handle='$handle'));

    my ($eternal) = $sth->fetchrow;
    return $eternal unless (!$eternal);

    &interr("return_eternal, couldn't find eternal: $sql");
}
   
#-----------------------------------------------------------------------------
# Sub return_handle, fetches handle given an eternal
# creates and checks a global cache of handles
# args: eternal
# returns: handle
# checked 6/21/2002 pirmann
#-----------------------------------------------------------------------------
sub sql_return_handle {
    my ($eternal) = @_;

    if (defined $Handle_Cache{$eternal}) {
	return $Handle_Cache{$eternal};
    } else {

	my $sth = &do_sth ( qq(select handle from cit_users
			       where eternal=$eternal));
	
	my ($handle) = $sth->fetchrow;
	$Handle_Cache{$eternal}=$handle;
	return $handle unless (!$handle);
    }
    return "NOTFOUND?";
}
   
#-----------------------------------------------------------------------------
# sub lastlogin_info 
# args: eternal, hostname
# returns: nothing. exits on errors.
#-----------------------------------------------------------------------------
sub sql_lastlogin_info {

    my $nowtime = time();

    $USER{'timescalled'}++;

    &do_sth ( qq(update cit_users set 
		 timescalled=$USER{'timescalled'},
		 lastcall=$nowtime,
		 timetoday=$USER{'timetoday'},
		 host='$hostname'
		 where eternal=$eternal));

}

sub ask_edit_user {
    print "Edit which user? ";
    my $who = &getline(50);
    my ($h, $e) = &sql_is_user($who);

    if ($e>0) {
	&cit_alog ($eternal, "edited user $h (#$e)");
	&edit_user($e);
    }
}

sub read_user {
    my ($whoto,$eternal,$axlevel) = @_;

    my $x;

    if ($whoto==0) {
	print "Who to read";
	if ($lasthandle) {
	    print "[$lasthandle]: ";
	} else {
	    print ": ";
	}
	$whoto=&getline($CONFIG{'DEFAULT_HANDLEMAX'});
	if (length($whoto)<1) {
	    if ($lasthandle) {
		$whoto=$lasthandle;
	    } else {
		return;
	    }
	} 
	$whoto = (&sql_is_user($whoto))[1];
    }

    if ($whoto < 0) {
	print "No such user.\n";
	return;
    }
	
#    print STDERR "WHOTO: $whoto\n\n";
    

    # for the duration of this routine, if the user is reading
    # himself, they are "aide" i.e. see all account details.
    $axlevel = $CONFIG{'AXLEVEL_AIDE'} if ($eternal == $whoto);


    my $sth = &do_sth ( qq(select eternal, handle, regis, perm,
			   lastold, expert, pause, prompt, hide,
			   editor, valid, screenwidth, screenlength,
			   lastcall, firstcall, timescalled, posted,
			   axlevel, timelimit, timetoday, timeonline,
			   name, addr, city, state, zip, phone, email, url,
			   host, bio from cit_users where
			   eternal=$whoto));

    my ($teternal, $handle, $regis, $perm, 
	$lastold, $expert, $pause, $prompt, $hide, 
	$editor, $valid, $screenwidth, $screenlength,
	$lastcall, $firstcall, $timescalled, $posted, 
	$taxlevel, $timelimit, $timetoday, $timeonline, 
	$name, $addr, $city, $state, $zip, $phone, $email, $url, 
	$host, $bio) = $sth->fetchrow;

    return unless (length($handle)>0);	
    
    my $sth = &do_sth ( qq(select cit_rooms.roomname from cit_rooms,cit_flags
			   where cit_flags.eternal=$teternal and
			   cit_flags.type=$CONFIG{'TYPE_RI'} and
			   cit_rooms.roomnum=cit_flags.roomnum
			   order by cit_rooms.roomname));

    my @rna; my $rn;
    while (my ($rn) = $sth->fetchrow) {
	push @rna, $rn;
    }
    $rn= join (/,/, @rna);

    print "User $handle (#$teternal), ",
    "Access Level: $AXLEVELS{$taxlevel}\n";
    print "Last login:  " . localtime($lastcall) . " from $host\n";
    print "First login: " . localtime($firstcall) . "\n\n";

    if ($timescalled==0) {$timescalled=1;}

    printf "Posts: %d\t\tCalls: %d\t\tRatio: %d\n",
    $posted, $timescalled, $posted/$timescalled;
    return if (&inclinecount(5));

    if ($axlevel >= $CONFIG{'AXLEVEL_AIDE'}) { 

	$hide=0;

	printf ("Validated: %s\t\tRegistered: %s\t\tPermanent: %s\n",
		&pyn($valid), &pyn($regis), &pyn($perm));

	printf ("Print Lastold: %s\tExpert Mode: %s\tUse Editor: %s\n",
		&pyn($lastold), &pyn($expert), &pyn($editor));

	printf ("Pause/Screen: %s\tPrompt/Message: %s\tHide Profile: %s\n",
		&pyn($pause), &pyn($prompt), &pyn($hide));

	printf ("Screenwidth: %d\t\tScreenlength: %s\n",
		$screenwidth, $screenlength);

	my $m= int($timetoday / 60);
	my $h= int($m/60); $m = $m - (60*$h);
	printf "\nTime Today: ${h}h ${m}m, ";

	my $h= int($timelimit/60); 
	my $m= int($timelimit%60);
	printf "Time Limit: ${h}h ${m}m, ";

	my $m= $timelimit-int($timetoday/60);
	print "Remaining Today: $m minutes, ";

	if ($timeonline < 84600) {
	    my $m= int($timeonline / 60);
	    my $h= int($m/60); $m = $m - (60*$h);
	    printf "Total Time: ${h}h ${m}m\n\n";
	} else {
	    my $d= int($timeonline / 84600);
	    $timeonline=int($timeonline % 86400);
	    my $m= int($timeonline / 60);
	    my $h= int($m/60); $m = $m - (60*$h);
	    printf "Total Time: ${d}d ${h}h ${m}m\n\n";
	}

	if (length($rna)>1) {
	    print "This user is room aide for: $rn\n\n";
	}

	return if (&inclinecount(7));
    }

    unless ($hide>0) {
	print "------------------------ Registration Info -----------------------\n";
	print "$name\n$addr\n",
	"$city     $state    $zip\n",
	"$phone\n$email\n$url\n";
	return if (&inclinecount(7));
    }

    if (length($bio) > 0) {
	print "------------------------ Biography -----------------------\n";
	#really should just print it. need a routine to print a blurb line by line.
	&message_format(decode_base64($bio));
    }
    print "\n";
#   &cit_alog ($eternal, "read user $handle");

}

sub validate_users {
    my ($axlevel) = @_;
    return -1 if ($axlevel < $CONFIG{'AXLEVEL_AIDE'});

    my $sth = &do_sth ( qq(select eternal from cit_users
			   where valid!=1 and regis=1 order by eternal));

    VALIDUSER: while ( my ($ueternal) = $sth->fetchrow) {
	
	my %REGIS=&get_user_registration($ueternal);

	print "\n$REGIS{'handle'} ($ueternal) from $REGIS{'host'}\n",
	"   $REGIS{'name'}\n",
	"   $REGIS{'addr'}\n",
	"   $REGIS{'city'}, $REGIS{'state'}, $REGIS{'zip'}\n",
	"   $REGIS{'phone'}\n",
	"   $REGIS{'email'}\n\n",

	"(V)alidate, (D)elete, force to (R)e-register, (S)top? ";

	my $option = &retkey('v', 'd', 'r', 's');

	if ($option eq 's') {
	    print "Stop";
	    return;
	} elsif ($option eq 'v') {
	    print "Validate";
	    &do_sth ( qq(update cit_users
			 set valid=1,axlevel=$CONFIG{'DEFAULT_AX_VALIDUSER'}
			 where eternal=$ueternal));
	    &cit_alog ($eternal, "validated user $REGIS{'handle'}");
	    next VALIDUSER;
	} elsif ($option eq 'd') {
	    print "Delete";
	    &do_sth ( qq(update cit_users
			 set axlevel=0,valid=1
			 where eternal=$ueternal));
	    &cit_alog ($eternal, "deleted user $REGIS{'handle'} during validation");
	    next VALIDUSER;
	} else {
	    print "Re-register";
	    &do_sth ( qq(update cit_users
			 set regis=0,valid=0
			 where eternal=$ueternal));
	    &cit_alog ($eternal, "forced user $REGIS{'handle'} to re-register during validation");
	    next VALIDUSER;
	}
    }
    print "\n";
}

sub check_needvalid {
    my ($axlevel) = @_;
    return -1 if ($axlevel < $CONFIG{'AXLEVEL_AIDE'});

    my $sth = &do_sth ( qq(select count(*) from cit_users
			   where valid!=1 and regis=1));
    
    my ($tmp) = $sth->fetchrow;
    return $tmp;
}
    
#-----------------------------------------------------------------------------
# sub get_rw_cit_flags
# sets up several arrays of room flags pertaining to the user, that
# are modifiable by the user, namely:
# Zapped_Room = Zapped Room arry
# Lastseen_Room = lastseen value arry
#-----------------------------------------------------------------------------
sub get_rw_user_flags {

    undef %Zapped_Room, %Lastseen_Room;

    my $sth = &do_sth ( qq(select type,roomnum,value from cit_flags
			   where eternal=$eternal
			   and type in ($CONFIG{'TYPE_LS'},$CONFIG{'TYPE_ZA'})));

    my $result = $dbh->selectall_arrayref($sth);
    foreach my $row (@$result) {
	my $type=@$row[0];
	my $roomnum=@$row[1];
	my $val=@$row[2];

	if ($type == $CONFIG{'TYPE_ZA'}) {
	    $Zapped_Room{$roomnum}=1;
	}

	if ($type == $CONFIG{'TYPE_LS'}) {
	    $Lastseen_Room{$roomnum}=$val;
	}
    }

    $sth->finish;

    #AIDE_ZAP feature <1 means they can't zap rooms.
    #so, return nothing (in case the option was turned on
    #after some aides zapped rooms.
    if  (
	 ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'}) &&
	 ($CONFIG{'FEATURE_AIDE_ZAP'} < 1)
	 ) {
	undef %Zapped_Room;
    }	
}

#-----------------------------------------------------------------------------
# sub get_r_cit_flags
# sets up several arrays of room flags pertaining to the user, that
# are only readable by the user and writable by Aides, namely:
# Roomaide_Room = roomaide status arry,
# Private_Room = private room permission arry
#-----------------------------------------------------------------------------
sub get_r_user_flags {

    undef %Roomaide_Room, %Private_Room;

    my $sth = &do_sth ( qq(select type,roomnum,value from cit_flags
			   where eternal=$eternal
			   and type in ($CONFIG{'TYPE_RI'},$CONFIG{'TYPE_PR'})));

    my $result = $dbh->selectall_arrayref($sth);
    foreach my $row (@$result) {
	my $type=@$row[0];
	my $roomnum=@$row[1];
	my $val=@$row[2];

	if ($type == $CONFIG{'TYPE_RI'}) {
	    $Roomaide_Room{$roomnum}=1;
	}

	if ($type == $CONFIG{'TYPE_PR'}) {
	    $Private_Room{$roomnum}=1;
	}
    }

    $sth->finish;
}

sub get_rw_user_prefs {
    my ($eternal, %XUSER) = @_;

    my $sth = &do_sth ( qq(select 
                           handle, password, regis, perm, lastold,
                           expert, pause, prompt, hide, editor, valid,
                           screenwidth, screenlength, lastcall,
                           firstcall, timescalled, posted, axlevel,
                           timelimit, timetoday, timeonline, host, 
			   smartspace, marchmode
			  
                           from cit_users
                           where eternal=$eternal));

    unless ( ($XUSER{'handle'},
	  $XUSER{'password'},
	  $XUSER{'regis'},
	  $XUSER{'perm'},
	  $XUSER{'lastold'},
	  $XUSER{'expert'},
	  $XUSER{'pause'},
	  $XUSER{'prompt'},
	  $XUSER{'hide'},
	  $XUSER{'editor'},
	  $XUSER{'valid'},
	  $XUSER{'screenwidth'},
	  $XUSER{'screenlength'},
	  $XUSER{'lastcall'},
	  $XUSER{'firstcall'},
	  $XUSER{'timescalled'},
	  $XUSER{'posted'},
	  $XUSER{'axlevel'},
	  $XUSER{'timelimit'},
	  $XUSER{'timetoday'},
	  $XUSER{'timeonline'},
	  $XUSER{'host'},
	  $XUSER{'smartspace'},
	  $XUSER{'marchmode'}) = $sth->fetchrow ) {
	&interr ("sub get_rw_user_prefs, no eternal $eternal\n");
    }
    $sth->finish;
    return %XUSER;
}

sub get_r_user_prefs {
    my ($eternal, %XUSER) = @_;
    my $sth = &do_sth ( qq(select 
                           handle, password, regis, valid, axlevel,
                           timelimit
			  
                           from cit_users
                           where eternal=$eternal));

    unless ( ($XUSER{'handle'},
	  $XUSER{'password'},
	  $XUSER{'regis'},
	  $XUSER{'valid'},
	  $XUSER{'axlevel'},
	  $XUSER{'timelimit'}) = $sth->fetchrow ) {
	&interr ("sub get_user_prefs, no eternal $eternal\n");
    }
    $sth->finish;
    return %XUSER;
}

sub get_user_registration {
    my ($eternal) = @_;    

    my $sth = &do_sth ( qq(select 
			   name, addr, city, state, zip, phone, email, handle, url
			   from cit_users
			   where eternal=$eternal));

    my @tmp; my %REGIS;
    if ( @tmp = $sth->fetchrow ) {
	$REGIS{'name'}=$tmp[0];
	$REGIS{'addr'}=$tmp[1];
	$REGIS{'city'}=$tmp[2];
	$REGIS{'state'}=$tmp[3];
	$REGIS{'zip'}=$tmp[4];
	$REGIS{'phone'}=$tmp[5];
	$REGIS{'email'}=$tmp[6];
	$REGIS{'handle'}=$tmp[7];
	$REGIS{'url'}=$tmp[8];
    }
    
    return %REGIS;
}


#===========================================================================
# enter the bio
#===========================================================================
sub enter_user_bio {

    my $sth = &do_sth ( qq(select bio from cit_users
			   where eternal=$eternal));
    my ($bio) = $sth->fetchrow;
    $sth->finish;

    $bio=decode_base64($bio);

    print "-------------------- Current bio -------------------\n";
    print "$bio\n";
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
	    print TMP "$bio";
	    close (TMP);
	}
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
	print "Saving your bio.\n";
	#slurp the whole file-- from the Perl FAQ.
	$string = do { local $/; <TURD> };
	close (TURD);
	unlink "$mytmpfile";
    } else {
	print "Saving empty bio anyway.\n";
	$string = '';
    }

    $string=encode_base64($string);
    &do_sth ( qq(update cit_users
		 set bio='$string'
		 where eternal=$eternal));
    
    &cit_alog ($eternal, "modified bio");
    unlink ("$mytmpfile"); #in case it's still hanging around
    return;
}

print "Version: " 
    . localtime( (stat(__FILE__))[9]) 
    . " " 
    . __FILE__ 
    . "\n"
    if ($DEBUG);

1;


