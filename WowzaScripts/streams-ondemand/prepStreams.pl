#!/usr/bin/perl -w
use strict;
#@author Jason Wolanyk
#@version 08152012
# This script is ment to be run as root.
# this script reads the files from the streams folder and
# adds them to wowza's startup stream list and generates
# sdp files for all of them and restarts wowza.

#opens streams dir and processes the information into Wowza's 
#StartupStreams.xml file
opendir(DIR,"streams"); 
open(CONF,">","/usr/local/WowzaMediaServer/conf/StartupStreams.xml") 
	or die("unable to open startup streams.xml\n");
print CONF "<Root>
    <StartupStreams>
";
while (readdir(DIR))
{
	if ($_ =~ m/\./){next;}
	print CONF "
	    <StartupStream>
	        <Application>live/_definst_</Application>
	        <MediaCasterType>rtp</MediaCasterType>
	        <StreamName>live/$_.sdp</StreamName>
	    </StartupStream>
	";
	open (FILE,"<","streams/$_") or die "unable to open $_\n";
	my $params=join(",",<FILE>);
	$params=~tr/\n/ /;
	close(FILE);
	print "prepping $_---------------------------------------\n";
	print "running ./streamLive.pl -file $_ $params\n";
	print `./streamLive.pl -file $_ $params`;
	print "done--------------------------------------------------------\n\n";
}
print CONF "	</StartupStreams>
</Root>
";
close(CONF);
#restart Wowza so it reads the file and starts the streams
print "restarting Wowza\n";
print `service WowzaMediaServer restart`;
print "Done\n Execution of $0 Complete\n";

