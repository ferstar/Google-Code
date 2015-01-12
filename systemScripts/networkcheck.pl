#!/usr/bin/perl -w
use strict;

#====================================================================
# Cron script to restart dhclient when in an odd state
# 7-17-2012
# @author John Ganz, Jason Wolanyk
# @version 2
# - fixed for new image
# - added more checks 
#====================================================================

my $dt = `date +%Y%m%d`; chomp($dt);
 
sub log()
{
	my $log = `tail -n 100 /var/log/syslog`|| "unable to read syslog"; 
	open(FILE, ">","/home/user/lastdown-$dt") 
		or die("This is an impossible error\n");
	print FILE "Last 100 entries to syslog before rebooting\n $log \n"; 
	close(FILE);
}

#@param ip to ping
#@return 
#	-1 = invalid input 
#	 0 = unreachable 
#	 1 = reachable 
#	 2 = unknown 
#@return -2 = this shouldnt happen
sub pingchk($)
{
	use Net::Ping;

	print "DEBUG $_[0]\n";

	my $p = Net::Ping->new("icmp");
	my $out= $p->ping("$_[0]")||"undef";
	$p->close();
	chomp $out;

	if ($out eq "undef")
	{
		if ($_[0] =~ 	#check if ip is valid
			m/^			#match start at begining
			([0-255]\.){3} # 3 numbers 0-255 followed by a dot
			[0-255]			# a number 0-255 not followed by a dot
			$/x) 			# end match at end of line, ignore whitespace in regex
			{
				print STDERR "unknown ip";			
				return 2;
			}
		elsif ($_[0] =~ 		#check dns name
			m/^					#match start at begining
			((\w|-)+\.)+	# match one or more  alphanumeric strings and a dot
			\w+			# match alpha numeric string
			$/x)				# end match at end of line ignore whitespace in regex
			{
				print STDERR "unknown host check dns\n";
				return 2;
			}
		else 
		{
			print STDERR "invalid ip/dns";
			return -1;
		}
	}
	else 
	{
		print STDERR "returning -$out-\n";
		return $out;
	}
	die("ERROR this should not happen something broke\n");
}

=block 
 check if has ip address
 continue or restart dhcp and log
 if sub can't connect to lovelace, it restarts network
 ping lovelace.rit.edu and rc.rit.edu 
 restart dhcp after 2nd ping fails
 ping 2 more times
=cut

my $out=&pingchk("lovelace.rit.edu"); 


#END

