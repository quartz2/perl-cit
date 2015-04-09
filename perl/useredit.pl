#===========================================================================
# edit_user, prompt the user for user options (with more stuff for aides). 
# do we need to keep track of WHAT it is they change... for the log?
#===========================================================================
sub edit_user {
    my ($xeternal) = @_;

    my %XUSER; my %XREGIS; my %changes;

    %XUSER=&get_rw_user_prefs($xeternal,%XUSER);
    %XUSER=&get_r_user_prefs($xeternal,%XUSER);
    %XREGIS=&get_user_registration($xeternal);
    
    my $cur_passwd=$XUSER{'password'};
    my $cur_lastold=$XUSER{'lastold'};
    my $cur_editor=$XUSER{'editor'};
    my $cur_expert=$XUSER{'expert'};
    my $cur_pause=$XUSER{'pause'};
    my $cur_prompt=$XUSER{'prompt'};
    my $cur_hide=$XUSER{'hide'};
    my $cur_scw=$XUSER{'screenwidth'};
    my $cur_scl=$XUSER{'screenlength'};
    my $cur_marchmode=$XUSER{'marchmode'};
    my $cur_smartspace=$XUSER{'smartspace'};
    my $cur_handle=$XUSER{'handle'};
    my $cur_axlevel=$XUSER{'axlevel'};
    my $cur_valid=$XUSER{'valid'};
    my $cur_regis=$XUSER{'regis'};
    my $cur_perm=$XUSER{'perm'};
    my $cur_timelimit=$XUSER{'timelimit'};
    my $cur_rname=$XREGIS{'name'};
    my $cur_addr=$XREGIS{'addr'};
    my $cur_city=$XREGIS{'city'};
    my $cur_state=$XREGIS{'state'};
    my $cur_zip=$XREGIS{'zip'};
    my $cur_email=$XREGIS{'email'};
    my $cur_phone=$XREGIS{'phone'};
    my $cur_url=$XREGIS{'url'};

    my $new_passwd=$cur_passwd;
    my $new_handle=$cur_handle;
    my $new_lastold=$cur_lastold;
    my $new_editor=$cur_editor;
    my $new_expert=$cur_expert;
    my $new_prompt=$cur_prompt;
    my $new_pause=$cur_pause;
    my $new_hide=$cur_hide;
    my $new_scw=$cur_scw;
    my $new_scl=$cur_scl;
    my $new_marchmode=$cur_marchmode;
    my $new_smartspace=$cur_smartspace;
    my $new_rname=$cur_rname;
    my $new_addr=$cur_addr;
    my $new_city=$cur_city;
    my $new_state=$cur_state;
    my $new_zip=$cur_zip;
    my $new_phone=$cur_phone;
    my $new_email=$cur_email;
    my $new_url=$cur_url;
    my $new_axlevel=$cur_axlevel;
    my $new_valid=$cur_valid;
    my $new_regis=$cur_regis;
    my $new_perm=$cur_perm;
    my $new_timelimit=$cur_timelimit;

    PRINT: while (1) {
	system "clear";
	my $tmp = $new_handle;
	$tmp =~ s{\\}{}g;
	print "Editing User $tmp (#$xeternal)\n\n";

	print "(a) Screen width.                             $new_scw ";

	print "\tCalls: $XUSER{'timescalled'}\n";

	print "(b) Screen length.                            $new_scl ";

	print "\tPosts: $XUSER{'posted'}\n";

	print "(c) Are you a Citadel expert?                 ";
	if ($new_expert == 1) {
	    print "Yes";
	} else {
	    print "No ";
	}

	print "\tTime On: $XUSER{'timeonline'}\n";

	print "(d) Print last old message when reading new?  ";
	if ($new_lastold == 1) {
	    print "Yes";
	} else {
	    print "No ";
	}

	print "\tTime Today: $XUSER{'timetoday'}\n";

	print "(e) Prompt after each message?                ";
	if ($new_prompt == 1) {
	    print "Yes\n";
	} else {
	    print "No \n";
	}

	print "(f) Pause each screenful of text?             ";
	if ($new_pause == 1) {
	    print "Yes";
	} else {
	    print "No ";
	}

	if ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'}) {
	    print "\t(t) Validated: ";
	    if ($new_valid == 1) {
		print "Yes\n";
	    } else {
		print "No \n";
	    }

	} else {
	    print "\n";
	}

	print "(g) Use editor by default?                    ";
	if ($new_editor == 1) {
	    print "Yes";
	} else {
	    print "No ";
	}

	if ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'}) {
	    print "\t(u) Registered: ";
	    if ($new_regis == 1) {
		print "Yes\n";
	    } else {
		print "No \n";
	    }

	} else {
	    print "\n";
	}

	print "(h) Hide registration info from others?       ";
	if ($new_hide == 1) {
	    print "Yes";
	} else {
	    print "No ";
	}

	if ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'}) {
	    print "\t(v) Permanent: ";
	    if ($new_perm == 1) {
		print "Yes\n";
	    } else {
		print "No \n";
	    }

	} else {
	    print "\n";
	}

	print "(i) Use march mode room navigation?           ";
	if ($new_marchmode == 1) {
	    print "Yes";
	} else {
	    print "No ";
	}

	if ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'}) {
	    print "\t(w) Axlevel: $AXLEVELS{$new_axlevel}\n";
	} else {
	    print "\n";
	}

	print "(j) Use smart space room navigation?          ";
	if ($new_smartspace == 1) {
	    print "Yes";
	} else {
	    print "No ";
	}

	if ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'}) {
	    print "   \t(x) Time Limit: " . $new_timelimit/60 . "\n";
	} else {
	    print "\n";
	}

	print "(?) See help on the above options.              ";

	if ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'}) {
	    print "   \t(y) Handle: $new_handle\n";
	} else {
	    print "\n";
	}

	print "                                                ";
	if ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'}) {
	    print "   \t(z) Password: $new_passwd\n";
	} else {
	    print "\n";
	}



	print "(k) Real name:         $new_rname\n";
	print "(l) Address:           $new_addr\n";
	print "                       $new_city, $new_state, $new_zip\n";
	print "(m) Phone:             $new_phone\n";
	print "(n) Email:             $new_email\n";
	print "(o) Webpage:           $new_url\n";

	print "\nEnter option to change,\n \"S\" to exit and save changes,\n \"Q\" to exit and discard changes: ";
	$option = &retkey('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l','m', 'n', 'o', 'q', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '?');
	print "$option\n";
	
# toggles: c,d,e,f,g,h,i
# aide toggles: o,p,r

	if ($option eq 'c') {
	    if ($new_expert==1) { $new_expert=0; } else { $new_expert=1; }
	} elsif ($option eq 'd') {
	    if ($new_lastold==1) { $new_lastold=0; } else { $new_lastold=1; }
	} elsif ($option eq 'e') {
	    if ($new_prompt==1) { $new_prompt=0; } else { $new_prompt=1; }
	} elsif ($option eq 'f') {
	    if ($new_pause==1) { $new_pause=0; } else { $new_pause=1; }
	} elsif ($option eq 'g') {
	    if ($new_editor==1) { $new_editor=0; } else { $new_editor=1; }
	} elsif ($option eq 'h') {
	    if ($new_hide==1) { $new_hide=0; } else { $new_hide=1; }
	} elsif ($option eq 'i') {
	    if ($new_marchmode==1) { $new_marchmode=0; } else { $new_marchmode=1; }
	} elsif ($option eq 'j') {
	    if ($new_smartspace==1) { $new_smartspace=0; } else { $new_smartspace=1; }
	} elsif ( ($option eq 't') && ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'})) {
	    if ($new_valid==1) { $new_valid=0; } else { $new_valid=1; }
	    $changes{"valid flag"}="from $cur_valid to $new_valid";
	} elsif ( ($option eq 'u') && ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'})) {
	    if ($new_regis==1) { $new_regis=0; } else { $new_regis=1; }
	    $changes{"regis flag"}="from $cur_regis to $new_regis";
	} elsif ( ($option eq 'v') && ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'})) {
	    if ($new_perm==1) { $new_perm=0; } else { $new_perm=1; }
	    $changes{"perm flag"}="from $cur_perm to $new_perm";
	} elsif ( $option eq '?') {
	    &formout($CONFIG{'FILE_OPTIONS'});
	    print "\nPress any key to continue.";
	    &getkey;

# integers: a,b
# aide integers: u

	} elsif ($option eq 'a') {
	    print "Enter screen width in columns [$new_scw]: ";
	    my $tmp=&getline(3);
	    $tmp *= 1;
	    if ($tmp > 1) {
		$new_scw=$tmp;
	    }
	} elsif ($option eq 'b') {
	    print "Enter screen length in rows [$new_scl]: ";
	    my $tmp=&getline(3);
	    $tmp *= 1;
	    if ($tmp > 1) {
		$new_scl=$tmp;

	    }
	} elsif ( ($option eq 'x') && ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'})) {
	    my $tlmin= $new_timelimit/60;
	    print "Enter time limit in minutes [$tlmin]: ";
	    my $tmp=&getline(3);
	    $tmp *= 1;
	    if ($tmp > 1) {
		$new_timelimit=$tmp*60;
		$changes{"timelimit"}="from $cur_timelimit to $new_timelimit";
	    }

# aide integers with a list: t 
	} elsif ( ($option eq 'w') && ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'})) {
	  NEWAX: print "New access level (? to list) [$new_axlevel]: ";
	    my $no = &retkey('0', '1', '2', '3', '4', '5', '?');
	    if ($no eq '?') {
		print "List\n";
		foreach my $x (0..5) {
		    print "$x, $AXLEVELS{$x}\n";
		}
		goto NEWAX;
	    } else {
		$new_axlevel=$no;
		$changes{"axlevel"}="from $cur_axlevel to $new_axlevel";
	    }

# strings: j,k,l,m,n

	} elsif ($option eq 'k') {
            print "FULL REAL name [$new_rname]: ";
            my $tmp = &getline(50);
	    if (length($tmp)>0) {
		$new_rname=$tmp;
		$changes{"realname"}="from $cur_rname to $new_rname";
	    }
	} elsif ($option eq 'l') {
            print "Street Address [$new_addr]: ";
            my $tmp = &getline(50);

	    if (length($tmp)>0) {
		$new_addr=$tmp;
		$changes{"address"}="from $cur_addr / $cur_city / $cur_state / $cur_zip to $new_addr / $new_city / $new_state / $new_zip";
	    }

            print "City/town [$new_city]: ";
            $tmp = &getline(50);
	    if (length($tmp)>0) {
		$new_city=$tmp;
		$changes{"address"}="from $cur_addr / $cur_city / $cur_state / $cur_zip to $new_addr / $new_city / $new_state / $new_zip";
	    }

            print "State/Country [$new_state]: ";
            $tmp = &getline(50);
	    if (length($tmp)>0) {
		$new_state=$tmp;
		$changes{"address"}="from $cur_addr / $cur_city / $cur_state / $cur_zip to $new_addr / $new_city / $new_state / $new_zip";
	    }

            print "Zip/Postal Code [$new_zip]: ";
            $tmp = &getline(50);
	    if (length($tmp)>0) {
		$new_zip=$tmp;
		$changes{"address"}="from $cur_addr / $cur_city / $cur_state / $cur_zip to $new_addr / $new_city / $new_state / $new_zip";
	    }

	} elsif ($option eq 'm') {
            print "Phone number [$new_phone]: ";
            my $tmp = &getline(50);
	    if (length($tmp)>0) {
		$new_phone=$tmp;
		$changes{"phone"}="from $cur_phone to $new_phone";
	    }
	} elsif ($option eq 'n') {
            print "Email address [$new_email]: ";
            my $tmp = &getline(50);
	    if (length($tmp)>0) {
		$new_email=$tmp;
		$changes{"email"}="from $cur_email to $new_email";
	    }
	} elsif ($option eq 'o') {
            print "Web home page (Optional) [$new_url]: ";
            my $tmp = &getline(150);
	    if (length($tmp)>0) {
		$new_url=$tmp;
	    }

# aide strings: y,z

	} elsif ( ($option eq 'y') && ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'})) {
            print "New Handle [$new_handle]: ";
            my $tmp = &getline($CONFIG{'DEFAULT_HANDLEMAX'});
	    if (length($tmp)>0) {
		$new_handle=$tmp;
		$changes{"handle"}="from $cur_handle to $new_handle";
	    }
	} elsif ( ($option eq 'z') && ($USER{'axlevel'} == $CONFIG{'AXLEVEL_AIDE'})) {
            print "New Password [$new_passwd]: ";
            my $tmp = &getline(-$CONFIG{'DEFAULT_PASSWDMAX'});
	    if (length($tmp)>0) {
		$new_passwd=&encrypt_passwd($new_handle,$tmp);
		$changes{"passwd"}="(changed password)";
	    }
	} elsif ($option eq 'q') {
	    print "Quit without saving? (Y)es, (N)o: ";
	    if (&yesno) {
		return;
	    }
	} elsif ($option eq 's') {
	    print "Save changes? (Y)es, (N)o: ";
	    if (&yesno) {
		&do_sth ( qq(update cit_users set
			     password="$new_passwd",
			     name="$new_rname",
			     addr="$new_addr",
			     city="$new_city",
			     state="$new_state",
			     zip="$new_zip",
			     phone="$new_phone",
			     email="$new_email",
			     url="$new_url",
			     handle="$new_handle",
			     lastold=$new_lastold,
			     editor=$new_editor,
			     expert=$new_expert,
			     prompt=$new_prompt,
			     pause=$new_pause,
			     hide=$new_hide,
			     screenwidth=$new_scw,
			     screenlength=$new_scl,
			     smartspace=$new_smartspace,
			     marchmode=$new_marchmode,
			     axlevel=$new_axlevel,
			     valid=$new_valid,
			     regis=$new_regis,
			     perm=$new_perm,
			     timelimit=$new_timelimit
			     where eternal=$xeternal));

		foreach $x (sort keys %changes) {
		    if ($eternal==$xeternal) {
			&cit_alog ($xeternal, "changed $x : $changes{$x}");
		    } else {
			&cit_alog ($eternal, "changed user $cur_handle : $x : $changes{$x}");
		    }
		}

		if ($xeternal==$eternal) {
		    %USER=&get_rw_user_prefs($eternal, %USER);
		}

		return;
	    }
	} else {
	    next PRINT;
	}
    }
}






print "Version: " 
    . localtime( (stat(__FILE__))[9]) 
    . " " 
    . __FILE__ 
    . "\n"
    if ($DEBUG);

1;


