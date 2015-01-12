#!/usr/bin/perl

##Note: This requires that you have a RSA Pub key on the nodes you want to hit
##Otherwise you will have to type in the password each time

##Revision: .1
##./nodes.pl node_addresses

use strict;
use warnings;


my $nodeFile = $ARGV[0];
my @nodeList;
my @outputList;

$ENV{DISPLAY} = ":0";

#sub to grab nodes specified
sub walker
{
    #read in list of nodes to walk
    print "-----------------------  Starting node listing  -----------------------\n";
    open(NODES, $nodeFile);
    while(<NODES>)
    {  
        chomp $_;
        push(@nodeList, $_);
        print "Node $_ added\n";
    }
    close(NODES);
    print "-----------------------  Node listing Complete  -----------------------\n\n\n";
}
sub startVNC
{
    my $node = $_[0];
    my @output;
    print "Connecting to $node\n";
    print "Will run: ssh $node \"x11vnc -once -usepw -safer -display :0\"\n";

    push(@output, `ssh $node "x11vnc -once -usepw -safer -display :0 &>>/dev/null&"`);
    `sleep 1`;
    `vncviewer -passwd /home/user/.vnc/passwd $node`;

    push(@outputList, "\n\nOutput for $node:\n");
    foreach my $outputLog (@output)
    {  
        push(@outputList, "$outputLog");
    }
}

walker();
foreach my $loc(@nodeList)
{
    startVNC($loc);
}
