#!/usr/bin/perl
use strict;
#disabled for testing purposes
#use warnings;
use Getopt::Std;
use File::Spec;

##############################################################
# Startvid.pl
# Script to pause grav execution and play a video file
#
# Changelog:
# Version 1.1.1 (5/18/2011)
#       - Fixed bug that caused program to halt execution when no file type was passed
#       - Fixed bug that caused program to SIGSTOP grav on an audio file (when passed an entire directory)
#       - Modified checkAudio sub to be multipurpose (look at comments above sub for explanation)
#
# Version 1.1 (5/18/2011)
#	- Major internal code moves (subs moved to top)
#	- Made different paths for read/write operations possible
#	- Implemented getopt::std
#       - Added audio exclusive support
#       - Added execution to select filetypes
#       - Changed logging method
#               - Next *full* revision (1.2) will remove vidFiles file
#
# Version 1.0
#	-initial release
##############################################################

#make sure that mplayer plays on the local display
#system("export DISPLAY=:0");
$ENV{DISPLAY} = ":0";

my %options=();
getopts("ahv:w:f:", \%options);

my $gravProc; #get the process ID of GRAV
my $random; #random number
my $randomEntry; #file to match random number above
my @alreadyPlayed; #files that were already played
my @alreadyPlayedCount; #used to get if was played 2x in one day
my $playThis; #file that will be run through mplayer
my $lastPlayed;  #object that was played last
my $lastPlayedCount;	# check to see if it has been played 2x
my $videoDirectory; #directory containing video files
my $writeDirectory; #directory that the output files should be written to
my $vidFiles; #abspath to vidFiles file
my $usedMedia; #abspath to usedMedia file
my $fileType = ''; #specifies what file should be looked for
my $audioMode; #specifies that audio should be played. Nothing more

#Sub to perform the update of what files are now in the videos directory
sub callUpdate
{
	`ls $videoDirectory | grep $fileType > $vidFiles`;
}

#sub to check arguements passed in
sub checkArgs
{
	#check to see if the user is looking for a specific filetype
	if($options{f})
	{
		if(index($options{f}, '.') == -1)
		{
			#someone forgot a period
			$options{f} = '.' . $options{f};
		}
		print "Looking for files of type $options{f}\n";
		$fileType = $options{f};
        }
	else
	{
		$fileType = '';
	}
        #check the video directory
	if($options{v})
	{
                chomp($options{v});
                if(-d $options{v})
                {
                        #there is a directory at that file
                        #now lets make sure the system knows it is a directory and not a regular file
                        if((substr $options{v},-1,1) ne '/')
                        {
                                $options{v} = $options{v} . '/';
                        }
                }
                else
                {
                        #someone is messing with us - and I dont like it.
                        die "No directory at specified path";
                }
                $videoDirectory = $options{v};
        }
        else
        {
                #assume this is for the original iteration
                $videoDirectory = "/home/nick/TedTalks/";
        }

        if($options{w})
        {
                chomp($options{w});
                if((substr $options{w},-1,1) ne '/')
                {
                        #we are checking contents of a directory. Make sure it *is* there
                        $options{w} = $options{w} . '/';
                }

                #check to see if the file actually exists
                if(-e $options{w}.'usedMedia'.$fileType) {}
                else 
                {
                        print "File " . $options{w} ."usedMedia" . $fileType . "does not exist. Assuming this is desired behavior\n";
                        system("touch " . $options{w} . "usedMedia" . $fileType);
                }
                if(-e $options{w}.'vidFiles'.$fileType) {}
                else 
                {
                        print "File " . $options{w} ."vidFiles" . $fileType . " does not exist. Assuming this is desired behavior\n";
                        system("touch " . $options{w} . "vidFiles" . $fileType);
                }
                $vidFiles = File::Spec->rel2abs($options{w} . 'vidFiles' . $fileType);
                $usedMedia = File::Spec->rel2abs($options{w} . 'usedMedia' . $fileType);
       }
       else
       {
                #assume this is for the original iteration
                $writeDirectory = "/home/user/playMedia/";

                #set variables
                $vidFiles = File::Spec->rel2abs($writeDirectory. 'vidFiles' . $fileType);
                $usedMedia = File::Spec->rel2abs($writeDirectory . 'usedMedia' . $fileType);

                #touch the files just in case they do not exist
                `touch $usedMedia $vidFiles`;
       }
}

#sanity check to make sure user is not feeding bad input to file filter
#optional arguement will cause this method to return 0 for video, 1 for audio
#optional arguement causes second requisite arguement
#### @_[0] = any value you want it to be
#### @_[1] = file extension
sub checkAudio
{
       my $checkMethod;
       $checkMethod = 1 if defined $_[0];

       my $audioFileTypes = '.mp3 .mp2 .flac .wma .ogg';
       my $videoFileTypes = '.mp4 .wmv .mpeg .mkv .avi';
        
       if($fileType ne '')
       {
               if(index($audioFileTypes, $fileType) == -1 && $audioMode == 1)
               {
                        print "Using unauthorized filetype for audio mode\n";
                        die "If this is a mistake contact shawn.hoerner\@gmail.com\n";
               }
               if(index($audioFileTypes, $fileType) != -1 && $audioMode == 0)
               {
                        print "You did not specify audio mode, yet are looking for a audio filetype\n";
                        die "Try again when you have a better idea of what you want to play\n";
               }
               if(index($videoFileTypes, $fileType) != -1 && $audioMode == 1)
               {
                        print "You specified audio mode yet are looking for video file types\n";
                        die "Try again when you have a better idea of what you want to play\n";
               }
               #I don't know how one arrives here, but if they do, we are not going to have to worry much longer...
               return 90;
        }
        if($checkMethod)
        {
                chomp ($_[1]);
                print "Arg passed: " . $_[1] . "\n";
                if(index($audioFileTypes, $_[1]) != -1)
                {
                        #is audio filetype
                        return 1;
                }
                elsif(index($videoFileTypes, $_[1]) != -1)
                {
                        #is video filetype
                        return 0;
                }
                else
                {
                        #File is not authorized type;
                        `logger startvid.pl recieved unrecognized filetype. Execution killed`;
                        print "Message logged to syslog - unrecognized filetype\n";
                        die "Filetype: '$_[1]'\; \$checkMethod = $checkMethod";
                }
        }
}

#sub to make sure that the file containing played media is not equal to the media incoming
sub compareFiles
{
	###### POSSIBLY deprecated through design... Commenting just in case
	#open(WC, "wc -l $vidFiles |");
	#open(WC2, "wc -l $usedMedia |");
	#while(<WC>) 
	#{ 
	#	my @spl = split(/ /, $_);
	#	$lineCount = int($spl[0]);
	#}
	#while(<WC2>) 
	#{ 
	#	my @split2 = split(/ /, $_);
	#	$usedLineCount = int($split2[0]);
	#}
	#close(WC);
	#close(WC2);
	if(`ls $videoDirectory | wc -l` eq `cat $usedMedia | wc -l`)
        {
                my @splitArray = split(/:/, `tail -n 1 $usedMedia`);
                for(my $q = 0; $q < scalar(@splitArray); $q++)
                {	
                        chomp($splitArray[$q]);
                        print "Iteration $q\n";
                        print "Array Entry: $splitArray[$q]\n";
                }
                if($splitArray[1] eq "1")
                {
                        print "This will be the last time this playlist will be run\n";
                        print "After next start, used media file will be deleted!\n";
                        #last media run, leave it be
                }
                else
                {
                        print "UsedMedia file is filled!\n";
                        print "Unlinking to restart playlist\n";
                        `rm $usedMedia`;
                        `touch $usedMedia`;
                }
        }
}

#sub to start a new file playing
sub callNew
{
	#assume we need new media
	#print "non special\n";
	#was played 2x or not at all...
	my $notRepeat = 0;
	my $testVar = 0;
	
	#loop to check if anything is repeating	
	while($notRepeat == 0)
	{
                my @mediums;
                #if no filetype is specified this peice would error out
                if($fileType != '')
                {
                        print "filetype specified\n";
                        @mediums = `ls $videoDirectory | grep \'$fileType\'`; #get the list of files that can be played
                        if(`ls $videoDirectory | grep $fileType | wc -l` == 0)
                        {
                                die "No media matching this filetype in $videoDirectory\n";
                        }
                }
                else
                {
                        print "filetype not specified\n";
                        @mediums = `ls $videoDirectory`;
                }
		my $randomValue = int(rand(scalar(@mediums))); #pick a random value to play with
		print "Random Value: $randomValue \t medium: $mediums[$randomValue]\n";
		$randomEntry = $mediums[$randomValue];
		if(scalar(@alreadyPlayed) < 1)
		{
			print "no media used yet, assuming its good\n";
			$notRepeat = 999;
			last;
		}

                #iterate through array for duplicates
		foreach my $test (@alreadyPlayed)
		{
			if(!defined($test))
			{
				#drop it
				print "Test not defined\n";
				$notRepeat = 999;
				next;
			}
			print "Random Entry: $randomEntry \t test: $test\n";
                        chomp($randomEntry);
                        chomp($test);
			
			if($randomEntry eq $test)
			{             					
				print "Duplicate found!\n";
				#do nothing, assuming everything has already been checked
				$testVar = 0;
				last;
			}
			else 
			{
				print "No duplicate found\n";
				$testVar = 1;
			}
		}

		if($testVar == 1)
		{
			$notRepeat = 999;
		}
	}

	if($notRepeat == 999)
	{
		#its showtime!!!
		print "Random entry: $randomEntry\n";
		$playThis = "$videoDirectory" . "$randomEntry";
		print " play this: $playThis\n";
		push(@alreadyPlayed, $randomEntry);
		push(@alreadyPlayedCount, "1");
	}

	doWrite();
	doPlay();
	exit();
}

#sub to write out the file that contains all the used entries
sub doWrite
{
	open(USEDWRITE, "> $usedMedia");
	for(my $counter = 0; $counter < @alreadyPlayed; $counter++)
	{
		if(length($alreadyPlayed[$counter]) > 1)
		{
			chomp($alreadyPlayed[$counter]);
			chomp($alreadyPlayedCount[$counter]);
			print "PlayWrite = $alreadyPlayed[$counter]:$alreadyPlayedCount[$counter]\n";
			print USEDWRITE "$alreadyPlayed[$counter]:$alreadyPlayedCount[$counter]\n";
		}
	}
	close(USEDWRITE);
}

#sub to do the final peice of the script - namely play!
sub doPlay
{
        #sanity check to make sure that a whole directory will not cause the script to kill grav
        #unintentionally.
        my $fileCheckType = checkAudio(1, substr($playThis, (rindex($playThis, '.'))));

        #pause grav if audio mode is not enabled
        pauseGrav() if ($audioMode != 1 && $fileCheckType == 0);
        
        #clean up runtime
        sanitize();

        #run mplayer
	print "mplayer cmd: mplayer -fs $playThis\n";
	system("mplayer -fs $playThis>>/dev/null");

        #resume grav execution
	resumeGrav() if ($audioMode != 1 && $fileCheckType == 0);
}

#sanitize the inputs!!!
sub sanitize
{
        #escape the spaces
        $playThis =~ s/ /\\ /g;

        #escape the '
        $playThis =~ s/'/\\'/g;
}

#sub to pause grav execution
sub pauseGrav
{
        $gravProc = `ps aux |grep grav | grep -v grep`;
        my @newGrav = split(/\s+/, $gravProc, 4);
        $gravProc = $newGrav[1];
        print "gravProc = $gravProc\n";
        print "Will run 'kill -stop $gravProc'\n";
        `kill -stop $gravProc`;
}

#Sub to resume grav execution
sub resumeGrav
{
        `kill -cont $gravProc`;
}

sub callHelp()
{
        print "Version 1.1\n\n";
        print "Usage: ./Startvid.pl\n";
        print "Script that will pause grav and play a video\n";
        print "\t-h\tPrint this help message\n";
        print "\t-v\tAlternate location for video files (defaults to: /home/nick/TedTalks\n";
        print "\t-w\tAlternate location to write output files (defaults to: /home/user/PlayMedia/\n\n";
        exit();
}


############################################################
#Begin primary execution
############################################################

callHelp() if defined $options{h}; #call for help - and thats it
$audioMode = 1 if defined $options{a}; #playing audio this round

#build a file/operating definitions
checkArgs();
checkAudio();

#we want to see if there are new files
callUpdate();

#See how long the file containing the names is
#compare this to what files have been run, if count matches restart file
compareFiles();

#dump the filenames of the used items
#notice the format of the file!!!!
#entry:playcount[starts at 1]
open(USEDITEMS, "cat $usedMedia |");
while(<USEDITEMS>)
{
	chomp($_);
	my @tempArray = split(/:/, $_);
	push(@alreadyPlayed, $tempArray[0]);
	push(@alreadyPlayedCount, $tempArray[1]);
}
close(USEDITEMS);

#check to see if the last element has been played 2x
$lastPlayed = pop(@alreadyPlayed);
$lastPlayedCount = int(pop(@alreadyPlayedCount));
push(@alreadyPlayed, $lastPlayed);
push(@alreadyPlayedCount, $lastPlayedCount);

#grep the list of usedMedia to see if there is a entry that corresponds to ':1'
my $usedItem = "0";
open(USEDITEMS, "cat $usedMedia | grep :1 |");
while(<USEDITEMS>)
{
	print "$_\n";
	if(length($_) > 0)
	{
		#print "input line: $_\n";
		my @line = split(/:/, $_);
		$usedItem = $line[0];
	}
}

#if there is a used (and thus ready to be used) item
if($usedItem ne "0")
{
	$playThis = "$videoDirectory/$usedItem";
	my $incrementer = pop(@alreadyPlayedCount);
	push(@alreadyPlayedCount, "2");
	doWrite();
	doPlay();
	exit();
}
#or else we need to pick a different item
else
{
	callNew();
}

#if so, consider the last one the next source to play
#possibly deprecated - will be removed in next release if so
if(scalar(@alreadyPlayed) > 0 && length($lastPlayedCount) > 1 &&  $lastPlayedCount < 2)
{
	my $incrementer = pop(@alreadyPlayedCount);
	$incrementer++; #increment play count
	push(@alreadyPlayedCount, $incrementer);
	$playThis = $lastPlayed;
	doWrite(); #write the used files
	doPlay(); #run the program!
	exit(); #our job here is done
}
