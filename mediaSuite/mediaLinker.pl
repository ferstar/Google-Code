#!/usr/bin/perl

################################################################################
# MediaLinker Script
# Dev: Shawn Hoerner
# Version: 0.2
# Release Date: 10/18/2011
#
# Purpose:
#   Script designed to replace various player scripts developed by RC, this serves
#   to be a multipurpose script for playing most media files. With the capacity to play
#   slideshows, this script will prove vital for future work.
#                          --------------------------
# Todo's:
#   - Work on file checking
#   - Check even playlist
#                          --------------------------
# Changelog:
#   - 0.2 (10/18/2011)
#       - Initial commit
#       - Basic functionality completed
#       - Simple controls added
################################################################################
use strict;
use warnings;
use Getopt::Std;                       #used for arguement handling
use List::Util 'shuffle';              #used to randomize array
use Cwd;
use List::MoreUtils;

my $mediaPlayer = 'mplayer';
my $mediaPlayerArgs = '-fs';
my $processControl = 1;                #boolean used to determine if grav should be stopped. Assuming default yes.
my $processSpec = 'grav';
my $allowAudio = 0;
my $allowVideo = 0;
my $allowImage = 0;
my $allowUnknown = 0;
my $playlistFile;
my $randomType = 0;
my $evenize = 0;
my $evenCount = 5;                      #assume 5 plays is a good average play number
my $gravTime = 15;                      #Default grav time = 15 minutes

#Mediatypes that can be played
#   0 - Audio
#   1 - Video
#   2 - Images
#   3 - Unknown media types
my @allowedMedia = qw(0 0 0 0);

#make sure that mplayer plays on the local display
#system("export DISPLAY=:0");
$ENV{DISPLAY} = ":0";

my %options=();
getopts("AcehIiRrUVIURE:f:d:P:p:m:a:T:F:", \%options);

################################################################################
################### Subs used for basic media functionality ####################
################################################################################
#Sub to get directory this script resides in
#ARGUEMENTS:
#   None
#RETURNS:
#   abspath to this directory
sub getDir
{
    my $scriptFullPath = Cwd::abs_path($0);
    my $directory = substr($scriptFullPath, 0, (rindex($scriptFullPath, '/') + 1)) ;
    return $directory;
}
#Sub to convert allowedMedia array tostring
#ARGUEMENTS:
#   NONE
#RETURNS:
#   String containing allowed media types
sub allowToString
{
    my $returnString = "";
    if($allowedMedia[0] == 1)
    {
        $returnString = $returnString . " audio ";
    }
    if($allowedMedia[1] == 1)
    {
        $returnString = $returnString . " video ";
    }
    if($allowedMedia[2] == 1)
    {
        $returnString = $returnString . " images ";
    }
    if($allowedMedia[3] == 1)
    {
        $returnString = $returnString . " any ";
    }
    return $returnString
}
#Sub to pause/resume process
#ARGUEMENTS:
#   $_[0] - boolean value to pause/stop process (0 pauses, 1 starts)
sub processController
{
    my $targetProcess = `ps aux | grep $processSpec | grep -v grep`;
    my @newProcess = split(/\s+/, $targetProcess, 4);
    $targetProcess = $newProcess[1];
    
    if($_[0] == 0)
    {
        #Pause the grav frontend
        print "Pausing Grav\n";
        system("kill -stop $targetProcess");
    }
    elsif($_[0] == 1)
    {
        print "Resuming Grav\n";
        system("kill -cont $targetProcess");
    }
}

#Sub to play a single file
#THIS IS AN EXIT METHOD!!!!!
#ARGUEMENTS:
#   $_[0] - abspath to a file that will be played using the media player
sub playSingle
{
    my $file = $_[0];
    processController(0) if $processControl == 1;             #Pause GRAV
    system("$mediaPlayer $mediaPlayerArgs $file 2>1 >>/dev/null"); #Execute media player
    processController(1) if $processControl == 1;             #Resume GRAV
    exit(0);
}

#Sub to play a set of multiple files
#THIS IS AN EXIT METHOD!!!!!
#ARGUEMENTS:
#   $_[0] - array reference to abspath array of files
sub playMultiple
{
    my $fileRef = $_[0];
    my $files = join " ", @$fileRef;
    
    foreach my $file (@$fileRef)
    {
        print getFile($file);
        if(getFile($file) eq 'audio')
        {
            processController(1) if $processControl == 1;             #Resume GRAV
        }
        else
        {
            processController(0) if $processControl == 1;             #Pause GRAV
        }
        print "Running: $mediaPlayer $mediaPlayerArgs $file\n";
        system("$mediaPlayer $mediaPlayerArgs $file 2>1 >>/dev/null"); #Execute media player
        processController(1) if $processControl == 1;             #Resume GRAV
    }
    
    exit(0);
}

sub playFeh
{
    my $fileRef = $_[0];
    my $files = join " ", @$fileRef;
    system("$mediaPlayer $mediaPlayerArgs $files");
    
    my $switcherProcess = (split(/\s+/, `ps aux | grep autoswitch.pl | grep -v grep`, 4))[1];
    system("kill -9 $switcherProcess");
    exit(0);
}
#Sub to enable randomize set of files - no history
#ARGUEMENTS:
#   $_[0] - array reference to abspath array of files
#   $_[1] - &Play (0 - no play, 1 - play utilizing playMultiple)
#       Passing no value to this arguement will assume noplay
#       Passing 1 to this sub WILL make this an EXIT METHOD!!!!!
sub randomizeSet
{
    shuffle(@$_[0]);
    if($_[1] == 1)
    {
        playMultiple($_[0]);
    }
}
#Sub to randomize with consideration to the playcount
#ARGUEMENTS:
#   $_[0] - array reference to abspath files to play
#   $_[1] - array reference to play count
#   $_[2] - Maximum times that an item should be played.
#           Items equal to or greater than this value will be automatically dropped from running
#   $_[3] - Process to take.
#           0 - randomize and return next play
#           1 - randomize and play (EXIT METHOD!)
#   $_[4] - Aim for evenness (play all enteries first then redo or play as the computer finds them)
#           0 - make sure each value is the same before incrmenting
#           1 - let random pick how many times to play something
#   $_[5] - abspath to output file. Passing no arguement will result in 'playlist' file output
sub randomizeWithPlaycount
{
    my $playlistRef = $_[0];
    my $playcountRef = $_[1];
    my $maxCount = $_[2];
    my $executionType = $_[3];
    my $randomType = $_[4];
    my $outputFile = 'default';
    $outputFile = $_[5] if defined $_[5];
    
    my $highestValue = -1;      #highest item count (start in the negatives so *all* values are higher)
    my $highestLocation = -1;
    my $lowestValue = $_[2];    #lowest item count (start at top so *all* values are lower)
    my $lowestLocation = -1;
    
    my @removeList;             #elements that will be removed from the array for various reasons
    my $selectedFile;
    
    for(my $counter = 0; $counter < scalar(@$playlistRef); $counter++)
    {
        if(@$playcountRef[$counter] >= $maxCount)
        {
            #add to remove list
            push(@removeList, $counter);
        }
        else
        {
            if(@$playcountRef[$counter] > $highestValue)
            {
                $highestValue = @$playcountRef[$counter];
                $highestLocation = $counter;
            }
            if(@$playcountRef[$counter] < $lowestValue)
            {
                $lowestValue = @$playcountRef[$counter];
                $lowestLocation = $counter;
            }
        }
    }
    
    
    #Check to see if array will be emptied
    if((scalar(@$playlistRef)-scalar(@removeList)) < 1)
    {
        #oops... we are going to empty the array
        
        undef(@removeList); #empty the removal array (undef sets the array to near 0 memory value)
        
        foreach my $count (@$playcountRef) #Blank the count array
        {
            $count = 0;
        }
        
        $randomType = 1; #we can be at the mercy of perl's random function because there is no lower end
    }
    
    #clean array using splice @array $element to delete 1
    foreach my $location (@removeList)
    {
        splice @$playcountRef, $location, 1;
        splice @$playlistRef, $location, 1;
    }
    
    #depending on arguement 4 we pick the next value
    if($randomType == 0)
    {
        #This should function as a leveler for the entire file. 
        $selectedFile = @$playlistRef[$lowestLocation];
        @$playcountRef[$lowestLocation] ++;
        writeExtendedPlaylist($playlistRef, $playcountRef, $outputFile, 1);
    }
    elsif($randomType == 1)
    {
        my $randomNumber = int(rand(scalar(@$playlistRef)));
        
        #set the values, write enhanced output file.
        $selectedFile = @$playlistRef[$randomNumber];
        @$playcountRef[$randomNumber] ++;
        writeExtendedPlaylist($playlistRef, $playcountRef, $outputFile, 1);
    }
    
    #finish sub with argument 3 options
    if($executionType == 0)
    {
        return $selectedFile;
    }
    elsif($executionType == 1)
    {
        playSingle($selectedFile)
    }
}
#Sub to record playlist to file
#Will not record playcount
#ARGUEMENTS:
#   $_[0] - array reference to abspath array of files
#   $_[1] - abspath output file (passing an empty string for this arguement will result
#               a file created in the script directory called playlist)
#   $_[2] - boolean value specifying to overwrite the file or not (0 is no overwrite, 1 is overwrite)
#           ******** IF not passed, sub will assume no overwrite ********
sub writePlainPlaylist
{
    my $fileRef = $_[0];
    my $outputFile;
    my $overwrite = 0;      #Assume no overwrite
    $overwrite = $_[2] if defined $_[2]; #If the sub is passed an overwrite arguement, it takes precedence
    
    #Filepath
    if(length($_[1]) > 2)
    {
        $outputFile = $_[1];
    }
    else
    {
        $outputFile = getDir() . 'playlist';
    }
    
    open(OUTPUT_FILE, ">>$outputFile") if $overwrite == 0;
    open(OUTPUT_FILE, ">$outputFile") if $overwrite == 1;
    
    foreach my $file (@$fileRef)
    {
        print OUTPUT_FILE $file . "\n";
    }
    
    close OUTPUT_FILE;
}
#Sub to record playlist to file with playcounts
#Will not record playcount
#ARGUEMENTS:
#   $_[0] - array reference to abspath array of files
#   $_[1] - array reference of playcounts
#   $_[2] - abspath output file (passing 'default' for this arguement will result
#               a file created in the script directory called playlist)
#   $_[3] - boolean value specifying to overwrite the file or not (0 is no overwrite, 1 is overwrite)
#           ******** IF not passed, sub will assume overwrite ********
sub writeExtendedPlaylist
{
    my $fileRef = $_[0];
    my $countRef = $_[1];
    my $outputFile;
    my $overwrite = 1;      #Assume overwrite
    $overwrite = $_[3] if defined $_[3]; #If the sub is passed an overwrite arguement, it takes precedence
    
    #Filepath
    if($_[2] eq 'default')
    {
        $outputFile = $_[2];
    }
    else
    {
        $outputFile = getDir() . 'playlist';
    }
    
    open(OUTPUT_FILE, ">>$outputFile") if $overwrite == 0;
    open(OUTPUT_FILE, ">$outputFile") if $overwrite == 1;
    
    for(my $counter = 0; $counter < scalar @{$fileRef}; $counter++ )
    {
        print OUTPUT_FILE  @$fileRef[$counter] . ':' . @$countRef[$counter] . "\n";
    }
    
    close OUTPUT_FILE;
}

#Sub to parse plain playlist file
#ARGUEMENTS:
#   $_[0] - abspath to input file (Passing 'default' to this sub will result in file
#        playlist being opened for reading)
#   $_[1] - Array Reference that should have data pushed onto it
sub parsePlainFile
{
    my $file = $_[0];
    my $playlistRef = $_[1];
    my $INPUT_FILE;
    
    if($file eq 'default')
    {
        $file = getDir() . 'playlist';
    }
    open($INPUT_FILE, "<$file");
    
    while($INPUT_FILE)
    {
        push(@$playlistRef, chomp($_));
    }
    close($INPUT_FILE);
}
#Sub to parse plain playlist file
#ARGUEMENTS:
#   $_[0] - abspath to input file (Passing 'default' to this sub will result in file
#        playlist being opened for reading)
#   $_[1] - Array Reference that should have tracks pushed onto it
#   $_[2] - Array Reference that should have counts pushed onto it
sub parseExtendedFile
{
    my $file = $_[0];
    my $playlistRef = $_[1];
    my $countRef = $_[2];
    my $INPUT_FILE;
    
    if($file eq 'default')
    {
        $file = getDir() . 'playlist';
        system('touch ' . getDir() . ' playlist');  #touch the file and create it in case
    }
    
    if(system('wc -l ' . $file) eq "0")
    {
        #Empty file
        print "Playlist file is empty. Skipping reload\n";
    }
    else
    {
        open($INPUT_FILE, "<$file");
        
        while($INPUT_FILE)
        {
            my $line = chomp($_);
            my @splitLine = split /:/, $line, 2;
            push(@$playlistRef, $splitLine[0]);
            push(@$countRef, $splitLine[1]);
        }
        close $INPUT_FILE;
    }

}

#Sub to compare media elements found in directory and return play counts
#REQUIRES:
#   - playlistfile be defined
#       -if not defined, file 'default' will be created in script directory,
#           all values will be set to 0.
#ARGUEMENTS:
#   $_[0] - array reference of files to play (in abspath form)
#   $_[1] - Array reference of counts to play (will be filled)
sub getCounts
{
    my $playlist = $_[0];
    my $playCounts = $_[1];
    
    if(!defined $playlistFile || system('wc -l ' . $playlistFile) eq '0')
    {
        #write a blank file
        system("touch " . getDir() . 'playlist');
        
        #get number of elements in playlist
        my $elementCount = scalar(@$playlist);
        
        #create empty array
        my $blankString = "0 "x $elementCount;
        @$playCounts = split(/ /, $blankString);
    }
    else
    {
        my @playlistImportTracks;
        my @playlistImportCount;
        parseExtendedFile($playlistFile, \@playlistImportTracks, \@playlistImportCount);
        for(my $counter = 0; $counter < scalar(@$playlist); $counter++)
        {
            my $indexSearch = List::MoreUtils::first_index{$_ eq $playlistImportTracks[$counter]} @$playlist;
            if($indexSearch != -1)
            {
                @$playCounts[$counter] = $playlistImportCount[$counter];
            }
            else
            {
                @$playCounts[$counter] = 0;
            }
        }
    }
}
################################################################################
#####################  Subs for file specific operations  ######################
################################################################################

#sub to (attempt) detection of a filetype
#ARGUEMENTS:
#   $_[0] - abspath of file to be tested on
#   $_[1] - return string result
sub getFile
{
    my $inputFile = $_[0];
    my $isAudio = 0;
    my $isVideo = 0;
    my $isImage = 0;
    my @fileOutput = lc(`file $inputFile`);
    print "@fileOutput\n";
    for (my $counter = 0; $counter < @fileOutput; $counter++)
    {
        print "$counter : $fileOutput[$counter]\n";
        print index("mp3", $fileOutput[$counter]) . "\n";
    }
    
    if(index('audio', $fileOutput[0]) != -1) {return 'audio';}
    elsif(index('video', $fileOutput[0]) != -1) {return 'video';}
    elsif(index('image', $fileOutput[0]) != -1) {return 'image';}
    else
    {
        return 'unknown';
        #print "File input is not of recognizable media type\n";
        #print "Please check your source\n";
        #die if $allowUnknown != 1;
    }
}
#Sub to check all files for type (allows multiple execution with correct arguements)
#ARGUEMENTS:
#   $_[0] - array reference to abspath of files
#   $_[1] - type of files we can play (passed as string of audio/video/image)
sub checkAllFiles
{
    my $playReference = $_[0];
    my $playTypes = $_[1];
    my @removeList;
    for(my $counter = 0; $counter < scalar(@$playReference); $counter++)
    {
        if($playTypes != getFile(@$playReference[$counter]))
        {
            #tag for removal.
            push(@removeList, $counter);
        }
    }
    foreach my $remove(@removeList)
    {
        splice(@$playReference, $remove, 1);
    }
}
#Sub to check all files for type and play (allows multiple execution with correct arguements)
#checks with regard to allowed media types
#ARGUEMENTS:
#   $_[0] - array reference to abspath of files
sub checkFilesFromArguements
{
    my $playReference = $_[0];
    my $playTypes = $_[1];
    my @removeList;
    my $allowedTypes = allowToString();
    
    for(my $counter = 0; $counter < scalar(@$playReference); $counter++)
    {
        print "$counter:" .@$playReference[$counter] . "\n";
        if(index($allowedTypes, getFile(@$playReference[$counter])) == -1 && index($allowedTypes, 'any') == -1)
        {
            print "Pushing $counter to remove list (@$playReference[$counter])\n";
            #tag for removal.
            push(@removeList, $counter);
        }
    }
    foreach my $remove(@removeList)
    {
        splice(@$playReference, $remove, 1);
    }
}
#Sub to play PNG images
#ARGUEMENTS:
#   $_[0] - array reference to abspath of files
#   $_[1] - timeout (will default to 10 if no value is passed)
#THIS IS AN EXIT METHOD!
sub playImages
{
    my $timeout = 10;
    $timeout = $_[1] if defined $_[1];
    checkDependency('feh');
    
    $mediaPlayer = 'feh';
    
    #Arguements changed to create borderless windows and changed for updated arguements
    $mediaPlayerArgs = "--sort filename -F -x -Z -D $timeout";

    #execute (first start switching, then start feh)
    system("~/mediaSuite/autoswitch.pl -a feh -g $gravTime -t $options{T} &>>/dev/null&");
    playFeh($_[0]);
}

#Sub to check to see if a required program is installed
#ARGUEMENTS:
#   $_[0] - program name
#RETURNS:
#   0 if program is installed
#CALLS:
#   die if the program is not found
sub checkDependency
{
    my $programCheck = $_[0];
    system("which $programCheck");
    if($? != 0)
    {
        die "Required program: $programCheck not found. Please install and re-run\n";
    }
    return $?;
}

################################################################################
#################   Sub for parsing (and cleaning) user input   ################
################################################################################

#Sub to parse directory input
#ARGUEMENTS:
#   $_[0] - abspath directory
#   $_[1] - array reference to be filled
#   $_[2] - pick files of types specified from command line
#           Passing no arguement here will result in no processing
sub parseDirectory
{
    my $inputDirectory = $_[0];
    my $arrayReference = $_[1];
    
    opendir INPUT_DIRECTORY, $inputDirectory || die "Cannot open $inputDirectory for read\n";
    while(my $file = readdir(INPUT_DIRECTORY))
    {
        my @path = split(/\//, $file);
        if($path[-1] ne '.' && $path[-1] ne '..')
        {
            $file =~ s/\ /\\\ /g;
            $file =~ s/\'/\\\'/g;
            push (@$arrayReference, $inputDirectory . '/' . $file);
        }
    }
    closedir INPUT_DIRECTORY;
    
    if(defined $_[2])
    {
        checkFilesFromArguements(\@$arrayReference);
    }
    if(scalar(@$arrayReference) < 1)
    {
        die "No files found for play"
    }
}
#Sub to parse user arguements
#ARGUEMENTS:
#   $_[0] - array reference to be filled by parseDirectory
sub parseUserArgs
{
    if($options{h})                         #Help and exit
    {
        printHelp();
        exit(0);
    }
    
    if($options{A}){$allowedMedia[0] = 1;}  #Allow Audio
    if($options{V}){$allowedMedia[1] = 1;}  #Allow Video
    if($options{I}){$allowedMedia[2] = 1;}  #Allow Images
    if($options{U}){$allowedMedia[3] = 1;}  #Allow files of unspecified type

    if($options{r}){$randomType = 1;}       #randomize directory without a care
    elsif($options{R})                      #randomize directory according to play counts
    {
        $randomType = 2;
        if($options{e} && $options{E})                     #user wants even execution
        {
            $evenize = 1;
            $evenCount = $options{E};
        }
        elsif($options{e} && ! $options{E})
        {
            die "Please specify even count desired with -E [int]\n";
        }
    }    
    if($options{c}){$processControl = 0;}   #Disable control of a process
    if($options{P}){$processSpec = $options{P};} #Change what process will be paused
    if($options{p})                         #playlist file
    {
        $playlistFile = abs_path($options{p});
    }
    else
    {
        $playlistFile = 'default';
    }
    
    
    if($options{m})                         #User requests different media player
    {
        checkDependency($options{m});       #if program not found, program will die
        $mediaPlayer = $options{m};         #safe to assume success from above
    }
    if($options{a}){$mediaPlayerArgs = $options{a};}    #User requests different args
    ######################################
    ######     FILE INPUT SECTION    #####
    ######################################
    if($options{d})                         #Directory containing media
    {
        parseDirectory(Cwd::abs_path($options{d}), $_[0]);
    }
    elsif($options{F})
    {
        #Make Komodo JIT compiler stop complaining
        my $arrayRef = $_[0];
        push (@$arrayRef, Cwd::abs_path($options{F}));
    }
    elsif($options{f})
    {
        playSingle(Cwd::abs_path($options{f})); 
    }
    else{die "No input specified!\n";}
    ######################################
    ########       END INPUT       #######
    ######################################

    ######################################
    ####### DATA PROCESSING SECTION ######
    ######################################
    if($options{i})
    {
        playImages($_[0]);
    }
}

################################################################################
#############               Actual user processing!!!!             #############
################################################################################
my @mediaItems;
my @playcountItems;
parseUserArgs(\@mediaItems);
if($randomType == 0)
{
    playMultiple(\@mediaItems);
}
elsif($randomType == 1) #user does not care about how files are randomized
{
    randomizeSet(\@mediaItems, 1);
}
elsif($randomType == 2) #user does care about how files are randomized
{
    my @playCounts;
    getCounts(\@mediaItems, \@playCounts);
    randomizeWithPlaycount(\@mediaItems, \@playCounts, -1, 1, 1);
}
elsif($randomType == 3) #user wants even play
{
    my @playCounts;
    getCounts(\@mediaItems, \@playCounts);
    randomizeWithPlaycount(\@mediaItems, \@playCounts, $evenCount, 1, 0);
}
