#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use threads;
use threads::shared;
use File::Spec;
use Cwd;
use Cwd 'abs_path';

#Options HASH
my %options=();
getopts("hwpavnd:s:c:l:", \%options);
#add letters above for options
#using : means that it *needs* something after it (-x words)
#just a letter means -x will work

my @nodeList; #list of nodes
my $script; #abspath of script to be run
my $scriptName; #name of script that will be run
my $nodeFile; #file containing list of nodes
my $threadsPossible; #can this machine do threads?
my @threadList; #list of threads that are active
my @outputList :shared; #list of successful outputs, shared among threads (use of lock() method below)
my $move = 0; #Did we need to move the file?
my $runPerl = 0; #option to start perl instead of bash at ssh prompt
my @completedNodes :shared; #List of nodes completed

#print help
sub printhelp
{
    print "Version 1.2.5\n\n";
    print "Usage: ./AGWalker.pl -c walk.cmd -l walk.list\n\n";
    print "Script runs the provided script at each of the nodes on the provided list of nodes\n";
    print "\t-a\tPrint all help dialogs possible (Think a short man page)\n";
    print "\t-c\tScript that will be run (Same as -s)\n";
    print "\t-d\tDevice that script should run on (Send to single node only - will ignore list)\n";
    print "\t-h\tPrint help dialog\n";
    print "\t-l\tList of nodes to hit\n";
    print "\t-n\tDisables threading for execution\n";
    print "\t-p\tExecute PERL on remote command line, not BASH (BASH is default)\n";
    print "\t-s\tScript that will be run (Same as -c)\n";
    print "\t-v\tPrint version numbers/changelogs\n";
    print "\t-w\tPrint warnings dialog\n";
    print "Based off of script created by Matthew Leszczenski\n";
    print "Reimplemented in PERL by Shawn Hoerner (Originally to manuiplate threads)\n\n";
}

#print warnings
sub printwarning
{
    print "What happens if I break it?\n";
    print "\tAs in the original implementation, when it breaks the execution halts\n";
    print "\tUnlike the original version, when this fails, you will have x (number of nodes) failures realitively close together\n";
    print "\tBut this is why we *test* our scripts on localhost first, right? <nudge>\n\n";

    print "What happens if I break it and don't know why I broke it?\n";
    print "\tCould have failed for some reason (unlikely), try again; see the definition of insanity\n\n";
    print "\t\t\tdefinition:insanity = Trying the exact same process over and over again expecting a different result\n\n";
    print "\tAdditionally, one could try to run this program with -n which will disable the thread blocks from executing\n\n";
    
    print "Well how do I fix it?\n";
    print "\tEarly testing shows the classic SIGINT (^C) is the best way to fix this\n\n";
    
    print "Fine, its broken and I did not do it (For once...)\n";
    print "\tAWESOME!!! That means you found a bug (or flaw in my code)\n";
    print "\tI congratulate you - send me an email saying what you did (including version) so I can fix it\n";
    print "\tOr file a issue on our google code database - http://code.google.com/p/collaborationgrid/issues/list\n\n";
}

#print versions
sub printver
{
    print "Version 1.2.5\n";
    print "\tSanity checks! Finally added the ability to ignore blank lines\n";
    print "\tFixed script location dependency (LOTS of code change)\n";
    print "\tMade script check its very own sub\n";
    print "\tInternal code cleanup\n\n";

    print "Version 1.2\n";
    print "\t -More code cleanup\n";
    print "\t -Fixed error if the user put a abspath for script\n";
    print "\t -Should have cleaned up output a slight bit more\n";
    print "\t\t -In threading, nodes will now wait to output complete till _after_ all output has been completed\n";
    print "\t -Added -p -- PERL execution mode (Script will default to BASH)\n";
    print "\t -Added -d -- Device execution mode (Now run on one device without re-writing a file)\n\n";
    
    print "Version 1.1.1\n";
    print "\t -internal code cleanup (and commenting)\n";
    print "\t -cleaned up outputs\n";
    print "\t\t -Got rid of hawthorne lines\n";
    print "\t -added -s (-c seems to be distracting at times)\n";
    print "\t -added -n (nothread option)\n\n";
    
    print "Version 1.1 - RC\n";
    print "\t -added the special help sections\n";
    print "\t -finalized threading tasks\n";
    print "\t -tested to see how broke broke can be\n";
    print "\t\t -Will try to work on eliminating this\n";
    print "\t -added mini-man page output\n\n";
    
    print "Version 1.0\n";
    print "\t -began coding from Matt's original BASH script\n";
    print "\t -no thread support yet(Proof-Of-Concept presently)\n";
    print "\t -seems to be working as per original spec\n\n";
}

#print all of the above
sub printMan
{
    `clear`;
    print "-----------------------  Help (-h)  -----------------------\n";
    printhelp();
    print "-----------------------  Version (-v)  -----------------------\n";
    printver();
    print "-----------------------  Warnings (-w)  -----------------------\n";
    printwarning();
    exit(0);
}

#sub to grab nodes specified
sub walker
{
    #read in list of nodes to walk
    print "-----------------------  Starting node listing  -----------------------\n";
    open(NODES, $nodeFile);
    while(<NODES>)
    {
        chomp $_;
        if(/^\s*$/)
        {
            print "Empty line pulled @ $.\n";
        }
        else
        {  
            push(@nodeList, $_);
            print "Node $_ added\n";
        }

    }
    close(NODES);
    print "-----------------------  Node listing Complete  -----------------------\n\n\n";
}

#sub to actually run through commands
sub runCommands
{
    my $node = $_[0];
    my @output;
    print "Walking $node\n";
    print "Will run: scp $script $node:/root/$scriptName\n";
    push(@output,`scp $script $node:/root/$scriptName`);
    if($runPerl == 1)
    {
    	push(@output, `ssh $node "perl /root/$scriptName"`);
    }
    else
    {
	    push(@output, `ssh $node "bash /root/$scriptName"`);
    }
    push(@output, `ssh $node "rm /root/$scriptName"`);
    
    
    lock(@outputList);
    push(@outputList, "\n\nOutput for $node:\n");
    foreach my $outputLog (@output)
    {
        push(@outputList, "$outputLog\n");
    }
    lock(@completedNodes);
    push(@completedNodes, "$node finished\n");
}

#Do file check
#TODO: make this sub far more generic
#ARGS: 0 must be a filename
sub fileCheck
{
    my $checkFile = $_[0];
    if((index($checkFile,"/")) != -1)
    {
        #this means that this is a directory based path
        $script = File::Spec->rel2abs($checkFile);
    }
    else
    {
        #assume it was a locally fed file
        $script = getcwd . '/' . $checkFile;
    }
    if(-e $script)
    {
        print "$script is a valid file, will use for command list\n";
    }
    else
    {
        die "$script is *not* a valid file. Please try again\n";
    }
    $scriptName = (split(/\//, $script))[-1];
}


printhelp() if defined $options{h}; #user wanted help (also default action)
printwarning() if defined $options{w}; #user wanted warnings
printver() if defined $options{v}; #user wanted version information
printMan() if defined $options{a}; #user wanted all of the above

#given script and list
if(($options{c} || $options{s}) && ($options{l} || $options{d}))
{
    if($options{p})
    {
	    $runPerl = 1;
    }
    print "\n\n-----------------------    Begin Initial Checks    -----------------------\n";
    
    my $tempCheck;
    if($options{c}) { $tempCheck = $options{c} }
    if($options{s}) { $tempCheck = $options{s} }
    
    chomp($tempCheck);
    #check to see if the file actually exists
    fileCheck($tempCheck);
    
    ###################################################
    #logic to check if there is a list file
    if($options{l} && -e $options{l})
    {
        print "$options{l} is a valid file, will use for node list\n";
        $nodeFile = $options{l};
    }
    elsif($options{d})
    {
    	`echo $options{d} > /tmp/node`;
	    print "Will hit: " . `cat /tmp/node` . "\n";
	    $nodeFile = "/tmp/node";
    }
    else
    {
        die "Valid file not passed for node arguement\n";
    }
    ########################################################
    print "-----------------------  Initial checks complete!  -----------------------\n\n";
    walker();
    
    #can this version run threads?
    $threadsPossible = eval 'use threads; 1';

    #yes it can, begin the run using threads
    if($threadsPossible && !$options{n})
    {
        print "-----------------------  Starting thread execution  -----------------------\n";
        #do thread like things
        foreach my $loc(@nodeList)
        {
            print "Creating Thread for $loc\n";
            my $thr = threads->create('runCommands', $loc); #create and send a thread to the runCommands sub 
            push(@threadList, $thr); #push the thread away and start over
        }
        foreach my $threading(threads->list()) #now that each thread is created
        {
            $threading->join(); #join the joinable ones and wait for term
        }
        
        #begin logfile write
        open(LOG, ">./log.dat");
        print LOG "-----------------------  Output Log  -----------------------\n";
        print LOG "-----------------------  For date: " . `date` . "\n";
        print LOG "#user, no news is good news here...\n";
        foreach my $a (@outputList)
        {
            print LOG "$a";
        }
        close(LOG);
        #logfile completed
	    foreach my $out (@completedNodes)
	    {
	        print $out;
	    }
    }
    #perl version out of date/user did not want threads. Run normally
    else
    {
        print "\n\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!  Threads have been disabled for this execution  !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
        #dont do thread like things
        #in other words, run the original script (ish)
        if($options{n})
        {
            print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!                Reason: User Request             !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n";
        }
        else
        {
            print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!               Reason: Not supported             !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
            print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!       Your PERL environment is out of date      !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
            print "!!!!!!!!!  We will run *single-threaded* this time, but please consider updating your system!  !!!!!!!!!!\n\n";
        }
        
    	#run the commands for each node sequentially
        foreach my $loc(@nodeList)
        {
            runCommands($loc);
	        print pop(@completedNodes);
        }
    }

    #Single device execution cleanup
    if($options{d})
    {
	    `rm /tmp/node`;
    }
    exit(0);
}
#got one or the other, need both
if((($options{c} || $options{s}) && (!$options{l} || !$options{d})) || ((!$options{c} || !$options{s}) && ($options{l} || $options{d})))
{
    print "Missing half of necessary requirements\n";

    printhelp();
}
#no opts specified, default to help
if(!$options{c} && !$options{l} && !$options{h} && !$options{w} && !$options{v} && !$options{a})
{
    printhelp();
}
