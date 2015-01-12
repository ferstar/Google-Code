#!/usr/bin/perl
#====================================================================
# Cron script to restart dhclient when in an odd state
# 6-12-2012
# @author John Ganz
#====================================================================

use warnings;
my $dt = `date +%Y%m%d`; chomp($dt);

# if sub can't connect to lovelace, it restarts eth0
sub downup{
      my @pingy = `ping -c 4 lovelace.rit.edu 2>&1`;
	foreach(@pingy){ 
	  if(($_ =~ /100% packet loss,/) || ($_ =~ /ping: unknown host/)){
	   `pkill dhclient`; sleep 2; `dhclient &`; sleep 2;
	   return 1;	
	  }		
	}	
}

if(downup()){
	sleep 5; 
	if(downup()){
	  sleep 5;
	  unless(-e "/home/user/lastdown-$dt"){ `touch /home/user/lastdown-$dt`;} 
	  open FILE, ">/home/user/lastdown-$dt" or die "This is an impossible error\n";
	  my $log = `tail -n 100 /var/log/syslog`; 
	# write last 10 minutes of syslog to this file
	  print FILE "Last 100 entries to syslog before rebooting\n $log \n"; close(FILE);		
	  #`/sbin/reboot`; 
	} 
}

