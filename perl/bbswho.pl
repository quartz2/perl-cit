#!/usr/local/bin/perl

# bbswho.pl - Routines pertaining to keeping track of who's online
# Part of Citadel/Quux 
# David Pirmann (pirmann@quuxuum.org)
# 6/18/1998

#===========================================================================
# init_btmp
# initialize the btmp record for the handle/tty pair
# try to find the hostname of the caller by various methods
#===========================================================================
sub init_btmp {

    foreach $x (sort keys %ENV) {
	print SQLLOG "$$ $x $ENV{$x}\n";
    }

    my $ipa = (split (/ /, $ENV{'SSH_CLIENT'}))[0];
    $ipa=~ s/::ffff://;
    my $aton = inet_aton($ipa);
    $hostname = gethostbyaddr($aton, AF_INET);
    print SQLLOG "errno $? $$ ipaddress $ipa hostname $hostname\n";
    if (length ($hostname) < 1) {
	$hostname=$ipa;
    }
    print SQLLOG "$$ ipaddress $ipa hostname $hostname\n";
    my ($ltime)  = time;
    my $my_tty = POSIX::ttyname(0);
    if (length ($my_tty) < 1) {
	$my_tty=$ENV{"SSH_TTY"}
    }

    &do_sth ( qq(delete from cit_btmp where tty='$my_tty'));
    &do_sth ( qq(insert into cit_btmp 
		 (eternal, tty, ltime, host, pid, doing) values
		 ($eternal, '$my_tty', $ltime, '$hostname', $$, '[Login]')));

}


#===========================================================================
# enter_btmp
# change the btmp doing process. 
#===========================================================================
sub enter_btmp {
    my ($string) = @_;
    $string=~ s/\'/\\\'/g;
#    $string=~ s/\"/\\\"/g;

    if ($string eq "entermsg") {
        &do_sth ( qq(update cit_btmp 
                     set doing=CONCAT('+', doing) 
                     where pid=$$));
 
    } else {
        &do_sth ( qq(update cit_btmp 
                     set doing='$string'
                     where pid=$$));
    }

    return;
}

#===========================================================================
# clear_btmp
# remove the btmp when a user logs off.
#===========================================================================
sub clear_btmp {
    my ($pid) = @_;
    unless ($pid>0) {
	$pid=$$;
    }
    &do_sth ( qq(delete from cit_btmp where pid=$pid));
    return;
}

#===========================================================================
# read_btmp
# the guts of printing the wholist
#===========================================================================
sub read_btmp {
    my $sth = &do_sth ( qq(select cit_users.handle,ltime,doing,custom
			   from cit_users,cit_btmp
			   where cit_btmp.eternal=cit_users.eternal
			   order by cit_users.handle));

    printf ("%-20.20s %-5s  %-15.15s %s\n",
	    'USER', 'LOGIN', 'DOING', 'COMMENT');

    while (my ($h, $l, $d, $c) = $sth->fetchrow) {

	my ($ss,$mm,$hh,$mday,$mon,$year,$wday,$x1,$x1) = localtime($l);
	my ($ttime) = sprintf "%2.2d:%2.2d", $hh, $mm;
	
	$d = " $d" unless ( $d =~ /^\+/);
	$d =~ s{\++}{\+}g;

	printf "%-20.20s %-5s %-15.15s  %s\n",
	$h, $ttime, $d, $c;
	return if (&inclinecount(1));
    }
    return;
}

#===========================================================================
# read_btmp_alternate
# show the more technical items of the wholist, pid, tty, etc.
#===========================================================================
sub read_btmp_alternate {
    my $sth = &do_sth ( qq(select cit_users.handle,ltime,doing,tty,cit_btmp.host,pid
			   from cit_users,cit_btmp
			   where cit_btmp.eternal=cit_users.eternal
			   order by cit_users.handle));

    printf ("%-20.20s %-5s  %-10.10s %-6.6s %-5.5s %s\n",
	    'USER', 'LOGIN', 'DOING', 'TTY', 'PID', 'HOST');

    while (my ($h, $l, $d, $t, $host, $pid) = $sth->fetchrow) {

	$t =~ s{/dev/}{};

	my ($ss,$mm,$hh,$mday,$mon,$year,$wday,$x1,$x1) = localtime($l);
	my ($ttime) = sprintf "%2.2d:%2.2d", $hh, $mm;
	
	$d = " $d" unless ( $d =~ /^\+/);

	printf "%-20.20s %-5s %-10.10s  %-6.6s %-5.5s %s\n",
	$h, $ttime, $d, $t, $pid, $host;
	return if (&inclinecount(1));
    }
    return;
}

#===========================================================================
# enter_btmp_custom
# read the custom wholist comment.
#===========================================================================
sub enter_btmp_custom {

    print "Set who list comment (return for blank): ";
    my $c=&getline(35);
    $c=~ s/\'/\\\'/g;
    &sql_enter_btmp_custom($c);
    return;
}

#===========================================================================
# clear_btmp_custom
# read the custom wholist comment.
#===========================================================================
sub clear_btmp_custom {
    
    print "Clear wholist entry (give pid #): ";
	my $tmp=&getline(6);
    $tmp *=1;
    &clear_btmp($tmp) if ($tmp>1);
    return;
}

#===========================================================================
# kill_pid
# remove a user based on pid
#===========================================================================
sub kill_pid {
    
    print "Kill what pid (see Alt Wholist for #): ";
	my $tmp=&getline(6);
    $tmp *=1;
    if ($tmp>1) {
	kill 1, $tmp ;
    }
    &cit_alog ($eternal, "killed pid $tmp");
    return;
}

#===========================================================================
# sql_enter_btmp_custom
# put the custom wholist comment into the database
#===========================================================================
sub sql_enter_btmp_custom {
    my ($comment)=@_;
    &do_sth ( qq(update cit_btmp 
		 set custom='$comment'
		 where pid=$$));

    return;
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

