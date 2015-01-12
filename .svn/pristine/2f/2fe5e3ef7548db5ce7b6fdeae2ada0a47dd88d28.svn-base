#!/usr/bin/perl

#Script to change node to its official callings
#accepts no arguements

use strict;
use warnings;

#get the ip that the node presently has
my $ip = `ifconfig | grep \"inet addr:129.21\" | awk -F: '{print \$2}' | awk '{print \$1}'`;
chomp($ip);
print "IP: $ip\n";

#get the host according to the nameserver
my $host = `nslookup $ip | head -n 5 | tail -n 1`; #make the nslookup of the name one line
chomp($host);

#get *only* the hostname from nslookup
my $hostname = (split(/\s/, $host))[3];
print "hostname: $hostname\n";

#remove all that fun rit.edu thing
my $localhost = (split(/\./, $hostname))[0];
print "localhost: $localhost\n";

print "-----------------------------------------------------------------------------------------\n";

#time for the fun!
print ">> echo $localhost > /etc/hostname\n";
system("echo $localhost > /etc/hostname; cat /etc/hostname");

print "\n>> service hostname start: ";
system("service hostname start");

print "\n>> apt-get update\n";
`apt-get update`;

print "\n>> apt-get upgrade -y\n";
system("apt-get upgrade -y");
