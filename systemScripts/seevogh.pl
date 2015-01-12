#!/usr/bin/perl
use Tk;
use LWP::Simple;
use warnings;
use strict;

#==============================================================================
# Version 1.0                                                                 |
# SeeVogh Starter with room ID's                                              |
# ./seevogh.pl                                                                |
# 	TAKES NO ARGUEMENTS						      |
# Author: Shawn Hoerner                                                       |
#==============================================================================


my ($roomID, $javaLoc);
my $entry;

BEGIN
{
    $javaLoc = `which javaws`;
    chomp($javaLoc);
    print "Java Web Start Executable located at: $javaLoc\n";
}

# Sub to open a room given an ID
#	THIS IS AN EXIT SUB
# ACCEPTS:
#  $_[0] - Room ID to start
#
# RETURNS:
#  NIL
sub startAndKill()
{
    #Get and sanitize entry from textbox
    my $roomID = $entry->get();
    $roomID =~ s/\D//g;
    my $outFile = '/tmp/seeFile.jnlp';
    
    #We have a filename now. Erase it if it exists. 
    if(-e $outFile)
    {
	unlink $outFile;
    }
    
    #Get the download ID from their admin page using CURL (can't get it elsewise)
    my $output = qx(curl --data "action=ext_join&meeting_id=$roomID" https://seevogh.com/wp-admin/admin-ajax.php);
    print $output ."\n";
    #Get just the download ID (strip some of the extra admin information)
    my @return = split(/\;/, $output);
    
    #Get it!
    my $wgetAddr = "https://seevogh.com/meetings/" . $roomID . "/SeeVogh_" . $return[0] . "_rec_version.jnlp";
    print "Getting: $wgetAddr \n";
    getstore($wgetAddr,$outFile);
    
    #Find and Kill Java
    system("pgrep java | xargs kill -9");
    
    #Start SeeVogh!
    exec("$javaLoc /tmp/seeFile.jnlp > /dev/null &");
}

# Sub to get SeeVogh room ID's
# ACCEPTS:
#  $_[0] - room name (where name is either 'HD' or 'high')
#
# RETURNS:
#  <Number> - Room ID Number
sub getSessionInfo
{
    my $roomName = $_[0];
    $roomID = undef;
    if($roomName eq 'high')
    {
	$roomID = 4911976231;
    }
    elsif($roomName eq 'HD')
    {
	$roomID = 7223969575;
    }
    
    my $output = qx(curl --data "action=ext_join&meeting_id=$roomID" https://seevogh.com/wp-admin/admin-ajax.php);

    #Get just the download ID (strip some of the extra admin information)
    my @return = split(/\;/, $output);
    print "Session Key:             $return[0]\n";
    print "HTTP Session Referer:    $return[2]\n";
    print "SeeVogh PHP Return Code: $return[3]\n";
    return $return[0];
}

# Sub to find and kill Koala based Javas
# ACCEPTS:
#  NIL
#
# RETURNS:
#  0  for success
#  -1 for failure
sub killKoalas
{
    my $javaStats = `pgrep java`;
    #Gotta keep things tasteful
    my @excuses = ("Commiting Koala Genocide", "Killing Koalas", "Embarking on Koala Hunting Expedition",
		    "Salting and Razing Eucalyptus Plantation", "Creating a Super-massive Highway Through Koala Habitation");
    chomp ($javaStats);
    
    if(length($javaStats) >= 1)
    {
	my $randomNumber = int(rand(length(@excuses)-1));
	print "Java Found Running. " . $excuses[$randomNumber] . ".\n";
	system("pgrep java | xargs kill -9");
	return 0;
    }
    else
    {
	print "Java not found running. No Koalas to kill.\n";
	return -1;
    }
}

# Sub to start a pre-determined SeeVogh room
#	THIS IS AN EXIT SUB
# ACCEPTS:
#  $_[0] - Persistent Room ID
#
# RETURNS:
#  NIL
sub seekAndKill
{
    my $persistRoom = $_[0];
    my $seevoghLoc = $ENV{"HOME"} . "/seevogh-$persistRoom.jnlp";
    
    print "Expecting SeeVogh JNLP file at: $seevoghLoc\n"; 
    
    if(-e $seevoghLoc)
    {
	killKoalas();
	exec("$javaLoc $seevoghLoc > /dev/null &");
    }
    else
    {
	print "SeeVogh Persistent $persistRoom does not exist in user home\n";
	print "Getting it.\n";
	my $sessionKey = getSessionInfo($persistRoom);
	
	#Get it!
	my $wgetAddr = "https://seevogh.com/meetings/" . $roomID . "/SeeVogh_" . $sessionKey . "_rec_version.jnlp";
	getstore($wgetAddr, $seevoghLoc);
	chmod 0755, $seevoghLoc;
	killKoalas();
	#Start SeeVogh!
	exec("$javaLoc $seevoghLoc > /dev/null &");
    }
}

#Open TKL/TK Window
my $mw = MainWindow->new;
$mw->geometry("300x200");
$mw->title("SeeVogh Start");
$mw->Label(-text => "SeeVogh Room ID")->pack;
$entry = $mw->Entry()->pack;
$mw->Button(
    -text => "OK",
    -command => sub{startAndKill()},
)->pack;
$mw->Button(
    -text => "Persistent High Room",
    -command => sub{seekAndKill("high")},
)->pack;
$mw->Button(
    -text => "Persistent HD Room",
    -command => sub{seekAndKill("HD")},
)->pack;

#Start.
MainLoop;