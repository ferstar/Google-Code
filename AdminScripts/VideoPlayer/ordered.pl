#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use File::Spec;
#===============================================================
# order.pl
# Script to pause grav execution and play a video file
#
# Changelog:
# Version 1.1.1.1 (6/22/2011)
#	- Set out to run the videos in a known sequential order (alphabetically by filename)
#	- Removed video count tracking since unneeded for playback in a known order
#	- Comments on subs are placed where they are executed (tail of this script)
#
# Version 1.1.1 (5/18/2011)
#       - Fixed bug that caused program to halt execution when no file type was passed
#       - Fixed bug that caused program to SIGSTOP grav on an audio file (when passed an entire directory)
#       - Modified checkAudio sub to be multipurpose (look at comments above sub for explanation)
#
# Version 1.1 (5/18/2011)
#       - Major internal code moves (subs moved to top)
#       - Made different paths for read/write operations possible
#       - Implemented getopt::std
#       - Added audio exclusive support
#       - Added execution to select filetypes
#       - Changed logging method
#               - Next *full* revision (1.2) will remove vidFiles file
#
# Version 1.0
#       -initial release
#=============================================================
$ENV{DISPLAY} = ":0";
my %options=();
getopts("ahv:w:f:", \%options);
my $gravProc; 		# Get the process ID of GRAV
my $playThis; 		# File that will be run through mplayer
my $videoDirectory; 	# Directory containing video files
my $writeDirectory; 	# Directory that the output files should be written to
my $vidFiles; 		# Abspath to vidFiles file
my $usedMedia; 		# Abspath to usedMedia file
my $fileType = ''; 	# Specifies what file should be looked for
my $audioMode; 		# Specifies that audio should be played. Nothing more

sub callHelp(){
        print "Version 1.1.1.1\n\n";
        print "Usage: ./Startvid.pl\n";
        print "Script that will pause grav and play a video\n";
        print "\t-h\tPrint this help message\n";
        print "\t-v\tAlternate location for video files (defaults to: /home/nick/TedTalks\n";
        print "\t-w\tAlternate location to write output files (defaults to: /home/user/PlayMedia/\n\n";
        exit();
}

sub callUpdate{
        if ($fileType) { `ls $videoDirectory | grep $fileType > $vidFiles`; }
        else { `ls $videoDirectory $fileType > $vidFiles`;  }  
}

sub compareFiles { 
        if(`cat $vidFiles | wc -l` eq `cat $usedMedia | wc -l`) {
             `rm $usedMedia`;
             `touch $usedMedia`;
        }       
}

sub checkArgs{
        #check to see if the user is looking for a specific filetype
        if($options{f}) {
                if(index($options{f}, '.') == -1){
                        #someone forgot a period
                        $options{f} = '.' . $options{f};
                }
                print "Looking for files of type $options{f}\n";
                $fileType = $options{f};
        }
        else{ $fileType = ''; }
        #check the video directory
        if($options{v}){
                chomp($options{v});
                if(-d $options{v}){
                        #there is a directory at that file
                        #now lets make sure the system knows it is a directory and not a regular file
                        if((substr $options{v},-1,1) ne '/'){
                                $options{v} = $options{v} . '/';
                        }
                }
                else{
                        #someone is messing with us - and I dont like it.
                        die "No directory at specified path";
                }
                $videoDirectory = $options{v};
        }
        else{
                #assume this is for the original iteration
                $videoDirectory = "/home/nick/TedTalks/";
        }

        if($options{w}){
                chomp($options{w});
                if((substr $options{w},-1,1) ne '/'){
                        #we are checking contents of a directory. Make sure it *is* there
                        $options{w} = $options{w} . '/';
                }

                #check to see if the file actually exists
                if(-e $options{w}.'usedMedia'.$fileType) {}
                else {
                    	print "File " . $options{w} ."usedMedia" . $fileType . "does not exist. Assuming this is desired behavior\n";
                        system("touch " . $options{w} . "usedMedia" . $fileType);
                }
                if(-e $options{w}.'vidFiles'.$fileType) {}
                else {
                        print "File " . $options{w} ."vidFiles" . $fileType . " does not exist. Assuming this is desired behavior\n";
                        system("touch " . $options{w} . "vidFiles" . $fileType);
                }
                $vidFiles = File::Spec->rel2abs($options{w} . 'vidFiles' . $fileType);
                $usedMedia = File::Spec->rel2abs($options{w} . 'usedMedia' . $fileType);
       }
       else{
		#assume this is for the original iteration
                $writeDirectory = "/home/user/playMedia/";

                #set variables
                $vidFiles = File::Spec->rel2abs($writeDirectory. 'vidFiles' . $fileType);
                $usedMedia = File::Spec->rel2abs($writeDirectory . 'usedMedia' . $fileType);

                #touch the files just in case they do not exist
                `touch $usedMedia $vidFiles`;
       }
}

# Makes sure user is not feeding bad input to file filter
# Optional arguement will cause this method to return 0 for video, 1 for audio
# Optional arguement causes second requisite arguement
# @_[0] = any value you want it to be
# @_[1] = file extension
sub checkAudio
{
       my $checkMethod;
       $checkMethod = 1 if defined $_[0];

       my $audioFileTypes = '.mp3 .mp2 .flac .wma .ogg';
       my $videoFileTypes = '.mp4 .wmv .mpeg .mkv .avi';
        
       if($fileType ne ''){
               if(index($audioFileTypes, $fileType) == -1 && $audioMode == 1){
                        print "Using unauthorized filetype for audio mode\n";
                        die "If this is a mistake contact shawn.hoerner\@gmail.com\n";
               }
               if(index($audioFileTypes, $fileType) != -1 && $audioMode == 0){
                        print "You did not specify audio mode, yet are looking for a audio filetype\n";
                        die "Try again when you have a better idea of what you want to play\n";
               }
               if(index($videoFileTypes, $fileType) != -1 && $audioMode == 1){
                        print "You specified audio mode yet are looking for video file types\n";
                        die "Try again when you have a better idea of what you want to play\n";
               }
               #I don't know how one arrives here, but if they do, we are not going to have to worry much longer...
               return 90;
        }
        if($checkMethod){
                chomp ($_[1]);
                print "Arg passed: " . $_[1] . "\n";
                if(index($audioFileTypes, $_[1]) != -1)   { return 1;   } # Is audio filetype
                elsif(index($videoFileTypes, $_[1]) != -1){ return 0;   } # Is video filetype
                else{
                        #File is not authorized type;
                        `logger startvid.pl recieved unrecognized filetype. Execution killed`;
                        print "Message logged to syslog - unrecognized filetype\n";
                        die "Filetype: '$_[1]'\; \$checkMethod = $checkMethod";
                }
        }
}

sub doPlay{
        # Makes sure that a whole directory will not cause the script to kill grav
        my $fileCheckType = checkAudio(1, substr($playThis, (rindex($playThis, '.'))));

        # Pauses grav if audio mode is not enabled
        pauseGrav() if ($audioMode != 1 && $fileCheckType == 0);
        
        # Clean up runtime
        sanitize();
        # Runs mplayer
        print "mplayer cmd: mplayer -fs $playThis\n";
        system("mplayer -fs $playThis>>/dev/null");

        # Resume grav
        resumeGrav() if ($audioMode != 1 && $fileCheckType == 0);
}

sub sanitize {
        #escape the spaces
        $playThis =~ s/ /\\ /g;

        #escape the '
        $playThis =~ s/'/\\'/g;
}

sub pauseGrav {
        $gravProc = `ps aux |grep grav | grep -v grep`;
        my @newGrav = split(/\s+/, $gravProc, 4);
        $gravProc = $newGrav[1];
        print "gravProc = $gravProc\n";
        print "Will run 'kill -stop $gravProc'\n";
        `kill -stop $gravProc`;
}

sub resumeGrav { `kill -cont $gravProc`; }
#================================================================================
# Begin primary execution

callHelp() if defined $options{h}; 		# Call for help - and thats it
$audioMode = 1 if defined $options{a}; 		# Enables audio if flag is set
checkArgs();					# Builds a file/operating definitions
checkAudio();					# Checks the audio mode
callUpdate();					# Gets a list of the video files from the video file directory
compareFiles();					# Compares the list from "callUpdate() to a list of already played files
						# If the updated list and already played list are the same, everything has
						# been played so the played list is reset.

my @sorted = `cat $vidFiles`;			# Alphabetical array of all the video files in the working directory
@sorted = sort @sorted;	
my $count = 0;					# Looping variable to increase when a value in @sorted matches a value in @played
my @played = `cat $usedMedia`;			# Regular array of the usedMedia file

if (scalar @played == 0){ 			# If there is nothing in the usedMedia file, it uses the first value in @sorted
	$playThis = "$videoDirectory/$sorted[$count]";
	open USED, ">>$usedMedia" or die $!; print USED $sorted[$count]; close USED;
        doPlay();
        exit();
}
else{
	foreach(@played){ if($_ eq $sorted[$count]) { $count++; } }			
	$playThis = "$videoDirectory/$sorted[$count]";
	open USED, ">>$usedMedia" or die $!; print USED $sorted[$count]; close USED;
	doPlay();
	exit();	
}
