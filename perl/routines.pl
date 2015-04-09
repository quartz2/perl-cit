#!/usr/local/bin/perl

sub do_sth {
    my ($sql) = @_;

    my $btime=time;
    my $retrycount=0;
    my ($filename, $line, $caller) = (caller(1))[1,2,3];

    $sql =~ s/\n|\r|\s+/ /gs;

    my $sth;

#    my $sth2 = $dbh->prepare("select count(*) from cit_config");
#    if ($sth2->execute) {
#	$sth = $dbh->prepare($sql);
#	$sth->execute || 
#	    &interr("error, $filename:$line:$caller, execute failed: $sql");
#    } else { #attempt to reconnect.
#	print "Sleeping 10 seconds to attempt database reconnect, please wait...\n";
#	sleep 10;
#	$dbh = DBI->connect($source) ||
#	    &interr("error, $filename:$line:$caller, dbi connect failed");
#
#	sleep 2;
#
#	$sth = $dbh->prepare($sql);
#	$sth->execute || 
#	    &interr("error, $filename:$line:$caller, execute failed: $sql");

# a better way?
  STHPREP:

     if ($DEBUG_SQL>0) {
	 if ($sql =~ /select/) {
	     $sth = $dbh->prepare("describe $sql");
	     $sth->execute();
	     
	     open (DLOG, ">>/tmp/dlog");
	     while ( my (@x) = $sth->fetchrow ) {
		 print DLOG "*************************************\n";
		 print DLOG "sql......$sql\n";
		 print DLOG "table....$x[0]\n";
		 print DLOG "type.....$x[1]\n";
		 print DLOG "poskeys..$x[2]\n";
		 print DLOG "actukey..$x[3]\n";
		 print DLOG "keylen...$x[4]\n";
		 print DLOG "ref......$x[5]\n";
		 print DLOG "rows.....$x[6]\n";
		 print DLOG "extra....$x[7]\n";
		 print DLOG "*************************************\n";
	     }
	     close (DLOG);
	 }
     }

    $sth = $dbh->prepare($sql);
    unless ($sth->execute) {
	print "Sleeping 10 seconds to attempt database reconnect, please wait...\n";
	$retrycount++;
	sleep 10;
	$dbh = DBI->connect($source) ||
	    &interr("error, $filename:$line:$caller, dbi connect failed");
	
	sleep 2;
	if ($retrycount>4) {
	    print "Too many retries. Goodbye!\n";
	    exit;
	}
	goto STHPREP;
    }

    $sql_count++; 

    my $etime = time;
    $etime=$etime-$btime;

    print SQLLOG "$$ $USER{'handle'} $filename:$line:$caller:$sql (" . $sth->rows() . ") ($etime sec)\n" if ($DEBUG_SQL>0);

    return $sth;
}

sub do_sth_finish {
#this one is no longer used 11/28/2007 dpirmann

    my ($sql) = @_;
    my $btime=time;
    my ($filename, $line, $caller) = (caller(1))[1,2,3];

    $sql =~ s/\n|\r|\s+/ /gs;

    my $sth = $dbh->prepare($sql);
    $sth->execute ||
	&interr("error, $filename:$line:$caller, execute failed: $sql");
    $sth->finish;

    $sql_count++; 

    my $etime = time;
    $etime=$etime-$btime;

    print SQLLOG "$$ $caller:$sql (" . $sth->rows() . ") ($etime sec)\n" if ($DEBUG_SQL);

    return $sth;
}

sub interr {
    my ($msg) = @_;
    print STDERR "$msg\n";
    die;
}

sub user_terminate {
    my ($method) = @_;

    if ($method==20) { 
	print "\nAre you sure? (y/n) ";
	return if (! &yesno);
    }

    if ($method>0) {
	&formout ($CONFIG{'FILE_GOODBYE'});
	&unset_terminal;
    }

    &clear_btmp(0);

    if ($timein) {
	my $nowtime=time;
	&do_sth ( qq(insert into cit_ulog
		     (eternal, host, pid, timein, timeout, posts,
		      mread, sqlcalls) values
		     ($eternal, '$hostname', $$, $timein, $nowtime,
		      $session_posts, $session_read, $sql_count+2)));

	$nowtime = $nowtime-$timein;

	&do_sth ( qq(update cit_users set
		     posted=posted+$session_posts,
		     timeonline=timeonline+$nowtime,
		     timetoday=timetoday+$nowtime
		     where eternal=$eternal));

	print STDERR "\n\n\nSQL COUNT IS $sql_count  time this call = $nowtime \n\n\n";

    }
    exit;
}

sub cit_alog {
    my ($eternal, $what) = @_;
    my $nowtime=time;
    $what=quotemeta($what);
    &do_sth ( qq(insert into cit_alog (eternal, timestamp, what) values
		 ($eternal, $nowtime, '$what')));
}

sub show_log {
    my ($axlevel,$type) = @_;
    my $handle; my $eternal; my $limit;

    if ($axlevel < $CONFIG{'AXLEVEL_AIDE'}) {
	print "Must be access level Aide to view the logs.\n";
	return -1 ;
    }
        
    print "Number of last X entries [20]: ";
    $limit = &getline($CONFIG{'DEFAULT_HANDLEMAX'});
    $limit *= 1;
    $limit = 20 unless ($limit);

    print "Limit to a particular handle? ";

    $handle = &getline($CONFIG{'DEFAULT_HANDLEMAX'});
    ($handle,$eternal) = &sql_is_user($handle);
    
    my $sth = &do_sth ( qq(select handle,eternal from cit_users));

    my %hary;
    while ( my ($h, $e) = $sth->fetchrow) {
	$hary{$e}=$h;
    }
    $hary{0}=' ';

    if ($type==78) {

	my $sth = &do_sth ( qq(select cit_ulog.eternal,cit_users.host,pid,timein,
			       timeout,posts,mread,sqlcalls,exitstat
			       from cit_users,cit_ulog
			       where cit_ulog.eternal=cit_users.eternal
			       order by timeout desc
			       limit $limit
			       ));

	printf "%-15.15s %-16.16s %-6.6s %5s %5s %5s %s\n",
	'USER', 'LOGIN', 'LOGOUT', 'POSTS', 'MREAD', 'SQL', 'HOST';

	WLOG1: while ( my ($h, $ho, $pid, $in, $out, $po, $mr, $sq, $ex) = 
		$sth->fetchrow) {

	    if ($eternal>0) {
		next WLOG1 unless ($h==$eternal);
	    }

	    my ($undef,$mm,$hh,$mday,$mon,$year,$undef,$undef,$undef) =
		localtime($in);

	    my $login = sprintf ("%2.2d/%2.2d/%4.4d %2.2d:%2.2d", 
			      $mon+1,$mday,$year+1900,$hh,$mm);

	    my ($undef,$mm,$hh,$mday,$mon,$year,$undef,$undef,$undef) =
		localtime($out);

	    my $logout = sprintf ("%2.2d:%2.2d", $hh,$mm);

	    printf "%-15.15s %s %s  %5d %5d %5d %s\n",
	    $hary{$h}, $login, $logout, $po, $mr, $sq, $ho;
	    return if (&inclinecount(1));
	}
    } else {
	my $sth = &do_sth ( qq(select eternal,timestamp,what
			       from cit_alog
			       order by timestamp desc
			       limit $limit
			       ));

	printf "%-15.15s %-16.16s %s\n",
	'USER', 'TIME', 'WHAT';

      WLOG2:	while ( my ($h, $in, $what) = $sth->fetchrow) {

	    my ($undef,$mm,$hh,$mday,$mon,$year,$undef,$undef,$undef) =
		localtime($in);

	    my $login = sprintf ("%2.2d/%2.2d/%4.4d %2.2d:%2.2d", 
			      $mon+1,$mday,$year+1900,$hh,$mm);

	    if ($eternal>0) {
		next WLOG2 unless ($h==$eternal);
	    }
	    printf "%-15.15s %s %s\n",
	    $hary{$h}, $login, $what;
	    return if (&inclinecount(1));
	}
    }

}
			      
sub pyn {
#pyn = print yes or no. Duh!
    my ($x) = @_;
    ($x==1) ? return "Yes" : return "No";
    return;
}

sub readconfig {
    my $sth = &do_sth ( qq(select property,value from cit_config));

    while (my ($p, $v) = $sth->fetchrow) {
	$CONFIG{$p}=$v;
    }
}

sub showconfig {
    foreach $x (sort keys %CONFIG) {
	print "$x => $CONFIG{$x}\n";
    }
    print "\n";
}

print "Version: " 
    . localtime( (stat(__FILE__))[9]) 
    . " " 
    . __FILE__ 
    . "\n"
    if ($DEBUG);

1;

