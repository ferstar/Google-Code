#!/usr/bin/perl -w
use strict;
use Net::Ping;

#====================================================================
# RUN AS ROOT!
# Script to automatically fix the network and ssh so a nodes will come back online automatically after
# network/power failure
#  
# @return 
# 	0 if network/ssh is ok 
#	negative number if the network could not be tested
# 	first digit is status of network
#	second is status of ssh
# @author John Ganz, Jason Wolanyk
# @version 7-17-2012
# - fixed for new image
# - added ssh check
#====================================================================
my $dt = `date +%Y%m%d`; chomp($dt);
my $output="\n=====RUNNING-`date +%H%M`=====\n\n";

#check network connection and tries to fix it
# -1 could not ping
# 0 network is ok
# 1 host was disconnected but fixed issue
# 2 host is connected but network is having issues
# 3 network is down 
sub netfix()
{	
	my $p = Net::Ping->new("icmp")||return -1;
	#check network if its ok return 0	
	my $temp = $p->ping("lovelace.rit.edu")||"0";
	if ($temp){return 0;}
	
	$temp = $p->ping("8.8.8.8")||"0";
	if ($temp)
	{
		$output .= "connected but unnable to reach lovelace\n";
		return 2; 
	}

	#restart network manager
	$output .= "restarting network manager\n".`/etc/init.d/network-manager restart 2>&1`;
	$temp = $p->ping("lovelace.rit.edu")||"0";
	if ($temp){return 1;}
	$temp = $p->ping("8.8.8.8")||"0";
	if ($temp)
	{
		$output .= "connected but unnable to reach lovelace\n";
		return 2; 
	}

	#restart interfaces
	$output .= "restarting interfaces\n";
	for (my $i=0;$i<3;$i++){$output.= `ip link set eth$i down 2>&1`;}
	sleep 5;	
	for (my $i=0;$i<3;$i++)	{$output.= `ip link set eth$i up 2>&1`;}
	sleep 10;
	
	#check the network again
	$temp = $p->ping("lovelace.rit.edu")||"0";
	if ($temp){return 1;}
	$temp = $p->ping("8.8.8.8")||"0";
	if ($temp)
	{
		$output .= "connected but unnable to reach lovelace\n";
		return 2; 
	}

	$output.="still broke\n";
	return 3;
}

#checks if ssh is running
#@return
# 0 ssh running
# 1 ssh was down but fixed
# 2 ssh is broke
# -1 should not happen
sub sshchk()
{
	#TODO check if ssh is running properly
	#check if ssh is running
	if(`ps aux | grep /usr/sbin/sshd | grep -v grep`)
	{
		$output.= "ssh running\n";
		return 0;
	}
	
	#fix try to fix ssh
	$output.= "ssh not running\n".`/etc/init.d/ssh start 2>&1`."\n";
	
	#check ssh again
	if(`ps aux | grep /usr/sbin/sshd | grep -v grep`)
	{
		$output.= "ssh running\n";
		return 1;
	}
	else 
	{
		$output.= "ssh not running\n";
		return 2;
	}
	return -1
}

my $ret=0;
$ret += (netfix()*10);#multiply by 10 so return tells status of both methods
$ret += sshchk();

if ($ret)
{
	my $log = `tail -n 100 /var/log/syslog` || "ERROR! unable to read syslog\n"; 
	$output.= "logging return is $ret \n";
	print $output;
	open(FILE, ">>","/home/user/lastdown-$dt") 
		or die("This is an impossible error\n");
	print FILE "Last 100 entries to syslog before rebooting\n $log \n"; 
	print FILE "Script output \n $output\n";
	close(FILE);
}

exit $ret;

