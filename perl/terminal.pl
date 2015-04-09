#!/usr/local/bin/perl


#print "gimme: ";
#$got = getline(-12);
#print "--> $got\n";
#print "length = " . length($got) . "\n";

sub set_terminal {
    $fd_stdin = fileno(STDIN);

    $term     = POSIX::Termios->new();
    $term->getattr($fd_stdin);
    $oterm     = $term->getlflag();
    
    $echo     = ECHO | ECHOK | ICANON;
    $noecho   = $oterm & ~$echo;
    
    $term->setlflag($noecho);
    $term->setcc(VTIME, 1);
    $term->setattr($fd_stdin, TCSANOW);

    $Interrupted = 0;   # to ensure it has a value
    $SIG{INT} = sub {   # trap control-c
        $Interrupted++;
    };
    $SIG{STOP} = sub {  # trap control-z
        $Interrupted++;
    };
    $SIG{TERM} = sub {  # trap TERM
	&user_terminate(-1);
    };
    $SIG{HUP} = sub {  # trap HUP
	&user_terminate(-1);
    };

    return;
}

sub unset_terminal {
    $term->setlflag($oterm);
    $term->setcc(VTIME, 0);
    $term->setattr($fd_stdin, TCSANOW);
    return;
}

sub yesno { #accept only y or n and return
    my $key = '';
    while (1) {
	my $key = &getkey;
	if ($key =~ /y/i) {
	    print "Yes\n"; return 1;
	} elsif ($key =~ /n/i) {
	    print "No\n"; return 0;
	}
    }
}

sub back {
    my ($spaces) = @_; 
    foreach (1..$spaces) {
	print "\b \b" ;
    }
    return;
}

sub getline {
    my ($lim) = @_;
    my ($string, $char, $echo, @wpos);

    if ($lim<0) { 
	$lim = (0-$lim); 
	$echo=1; 
    }    

  READLOOP:
    
    my $char = &getkey;
    $char = ord($char);
    $char = ($char & 127);

    goto READLOOP if ( $char == 27 );

# backspace at beginning of line
    goto READLOOP if ( (($char == 8 ) || ($char == 127))
		       && (length($string)==0));

# ^U or ^W at beginning of line
    goto READLOOP if ( (($char == 21) || ($char == 23))
		       && (! length($string)));

# ^U someplace on line
    if ( $char == 21) {
	&back (length($string));
	$string = "";
	goto READLOOP;
    }

# ^W someplace on line
    if ( $char == 23 ) {
	my ($remove_chars, $apop);
	$apop = pop @wpos;
	if (! $apop ) { # which means there are no spaces.
	    $remove_chars = length($string);
	} else {
	    $remove_chars = (length($string) - $apop) - 1;
	}
	&back($remove_chars);
	$string = substr ($string, 0, length($string)-$remove_chars);
	goto READLOOP;
    }

# keep track of spaces for ^W
    if ( $char == 32) {
	push @wpos, length($string);
    }

# reached the limit but the user isn't hitting enter.
    if (length($string)==$lim) {
	if ( ($char == 13) || ( $char == 10) ) {
	    print "\n\r";
	    return($string); 
	} elsif ( ($char==127) || ($char==8) ) {
	    $string = substr ($string, 0, length($string)-1);
	    &back (1);
	    goto READLOOP; 
	} else {
	    goto READLOOP;
	}
    }

# handle backspace
    if ( (($char == 8) || ($char == 127))
	 && ($string)) {
	$string = substr ($string, 0, length($string)-1);
	&back (1);
	goto READLOOP; 
    }

# handle cr/lf
    if (( $char == 13) || ( $char == 10)) {
	print "\n\r";
	return($string); 
    }

# append char to string
    $string .= chr($char);

    $echo ? print "*" : print chr($char);

    goto READLOOP;
}

sub retkey { #accept only what we've asked for
    my (@choices) = @_;

    my $key = '';

    while (1) {
	my $key = &getkey;
	$key =~ tr/A-Z/a-z/;
	foreach my $x (@choices) {
	    return $key if ($key eq $x);
	}
    }
}

sub retanykey { #just return what they type
    my $key = &getkey;
    $key =~ tr/A-Z/a-z/;
    return $key;
}

#---------------------------------------------------------------------------
# we're just going to suck a message. handle unformatted by not stripping 
# out the crlfs. if they didn't specify unformatted, strip out any crlf 
# that isn't *proceeded* by a space for formatting. we'll have to learn
# regular expressions to figure out how to do that. we'll just finesse 
# over it for now

# return (status, message)
# status = -1 for abort, 0 otherwise.

sub input_sucker {
    my ($mode) = @_;
    my ($done, $key, $old, $option, $string, $okey);

#    print "MODE = $mode\n";
#    we really just need to get the input into a buffer.
#    i wonder what the max length of a string is in perl.	
    
GETSOMEINPUT:
    $done=0;
    while (!$done) {
	
	my $key=&getkey;
	$okey = ord($key);
	
	if ( $okey==10 ) {
	    $okey=13;
	    $key="\r\n";
	}

	if ( $okey==4 && $mode==1 ) {
	    #then we have a control-d in unformatted mode
	    #jump out for the prompt
	    $done=1;
	    
	} elsif ( ($okey==13 && $old==13) && $mode==0) {
	    #then we have two returns, jump out for the prompt
	    $done=1;
	    
	} elsif (( $okey==8 || $okey==127 ) && (length($string))) {
	    #they hit backspace. remove it from the screen then kill it
	    &back(1);
	    $string = substr($string, 0, length($string)-1);
	    
        } elsif ( ($okey >= 32 && $okey <= 126) || $okey==13 ) { 
	    # key is in printable ascii range
	    $string .= $key;
	    print $key;
	    $old = $okey;
	}
    }	     

    $done=0;
    while (!$done) {

	print "<A>bort <C>ontinue <P>rint <S>ave -> ";
	$option = &retkey ('a', 'c', 'p', 's');

	if ($option eq 'a') { 
	    print "Abort\n";
	    print "Are you sure? (y/n) ";
	    return -1 if (&yesno);
	} elsif ($option eq 'c') {
	    print "Continue\n";
	    goto GETSOMEINPUT;
	} elsif ($option eq 's') {
	    print "Save\n";
	    return (0, $string);
	} elsif ($option eq 'p') {
	    print "Print formatted\n";
	    &message_format($string);
	}
    }
    return; # should never get here.
}

# getkey handles ALL the key input. in here, we'll need to handle
# the sleeping alarm if there is keyboard input awaiting.

sub sleepalarm {
    if ($USER{'axlevel'} >= $CONFIG{'AXLEVEL_AIDE'}) {
	print "Your session has fallen asleep.\n";
	enter_btmp("[Sleeping]");
	return;
    }
    
    print "\n\n";
    &formout ($FILE{'SLEEPING'});
    &user_terminate(-1);
}

sub getkey {
    my $char;

    eval {
	local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
	alarm $CONFIG{'FEATURE_SLEEPING'};
	sysread (STDIN, $char, 1);
	alarm 0;
    };
    if ($@) {
	# timed out
	&sleepalarm;
    }
    else {
	return $char;
    }
}


sub show_ords {
    my ($string) = @_;

    foreach $x (0..length($string)) {
	$char=substr($string, $x, 1);
	if (ord($char)==13) {
	    $ord=13;
	    $char="*CR*";
	} elsif (ord($char)==10) {
	    $ord=10;
	    $char="*LF*";
	} else {
	    $ord=ord($char);
	}
	print "$char($ord)";
    }
    print "\n\n";
}

sub inclinecount {
    my ($x) = @_;
    if ($x < 1) {
	$linecount++;
    } else {
	$linecount=$linecount+$x;
    }

    return unless ($USER{'pause'});

    if ($linecount >= $USER{'screenlength'}) {
	my $more = "---more---";
	print $more;
	my $key = &retanykey;
	return 1 if ($key eq 's');
	return 1 if ($key eq 'q');
	&back(length($more));
	$linecount=0;
    }
}

sub formout {
    my ($file) = @_;
    open (FILE, $file) || return;
    while (<FILE>) {
	print;
    }
    close (FILE);
}

print "Version: " 
    . localtime( (stat(__FILE__))[9]) 
    . " " 
    . __FILE__ 
    . "\n"
    if ($DEBUG);

1;

