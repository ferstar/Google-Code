#!/usr/bin/perl
#==============================================================================
# Version 8-24-12                                                             |
# Version for 5/15/2012                                                       |
# Autostart grav with cron, or easily from the CMD                            |
# ./start.pl    (default)                                                     |                       
# ./start.pl -h (for help)                            			      |
# @author John Ganz                                                           |
#==============================================================================

# Main script
use strict;  use warnings;  use Getopt::Long;
chdir '/home/user/grav';    # this is the default directory
checkState();           # exits sript if >4 gravs running
handleArgs();           # parse arguments and run script
# End Main script

#=hanldeArgs===============================================
# sub to parse arguments 
# calls help(), killgrav(), updateGrav() or findStreams()
sub handleArgs{
# get paramters from CMD
    my ($updateg, $kill, $IP, $ver, $gi, $help, $gravs, $not, $skip, $nodef, $res, $only,$inputfile,$nofile,$nobase);
    GetOptions('upgrav' => \$updateg, 'ifrun' => \$gi,'h' => \$help, 'i=s' => \$gravs, 'r=s' => \$res,
            'k' => \$kill, 'ip=s' => \$IP, 'skip=s' => \$skip, 'not=s' => \$not, 'nodef' => \$nodef, 'only=s' => \$only,
            'file'=>\$inputfile,'nofile'=>\$nofile,'nobase'=>\$nobase
            );


# calls subs based off of input
    if(($help) || ($nodef) && (!$IP)) { help(); }   
    elsif($kill)   { killgrav();     }
    elsif($updateg){ updateGrav();   }
    else           {
        findStreams(1, $not, $nodef, $IP, $skip, $res, $only, $inputfile, $nofile, $nobase) if !defined $gravs ;    # default to only one instance of grav        
            findStreams($gravs, $not, $nodef, $IP, $skip, $res, $only, $inputfile, $nofile, $nobase) if defined $gravs; # use specified amount of grav instances
    }       
}

#=findStreams===============================================
# generates a hash containing an even amount of streams per
# each instance of grav. Adds, deletes or skips screens
# calls findScreens()
sub findStreams{    
    my ($updateg, $kill, $IP, $ver, $gi, $help, $gravs, $not, $skip, $nodef, $res, $only,$inputfile,$nofile,$nobase);
    $gravs=$_[0], $not=$_[1], $nodef=$_[2], $IP=$_[3], $skip=$_[4], $res=$_[5], $only=$_[6], $inputfile=$_[7], $nofile=$_[8], $nobase=$_[9];
# default streams
    my %streamList2 = ( 	       'poli2'      , '233.17.33.246/50046',
            'gv'         , '233.17.33.230/50030', 
            'cleanroom'  , '233.17.33.232/50032' ,
            'globoffice' , '224.2.243.48/52850',
            'carey'      , '233.17.33.240/50040',
            'gccis'	    , '233.17.33.242/50042',	 );

#unused streams
#'poli1'        , '233.17.33.206/50004',	
#'business'     , '224.2.224.225/20002',

#Currently down streams				
#'sicoverhead'  , '233.17.33.212/50012',
#'gccisntid'    , '233.17.33.242/50042 ',
#'careyntid'    , '233.17.33.240/50040 ', 
#'gallaudet     , '233.17.33.252/50052 ' 
#delete built in vars
    if($nobase){ for(keys %streamList2){ delete $streamList2{$_}; }}


    if(-f '/home/user/grav/streams.list'){
        open FILE, "</home/user/grav/streams.list" or die $!;
        print ("loading streams.list\n");
        while (<FILE>) {
            next if $_ eq '';
            my @li = split(" ", $_);
            $streamList2{$li[0]} = $li[1] if !exists $streamList2{$li[0]};
        }
    }


#delet values from files if nofile is set
    if ($nofile){ for(keys %streamList2){ delete $streamList2{$_}; }}

# dont use any default streams  
    if($_[2]){ for(keys %streamList2){ delete $streamList2{$_}; }}

# load values from alternate file if specified	
    if (-f $inputfile)
    {
        open(FILE, "<",$inputfile) or die $!;
        print ("loading $inputfile\n");
        while (<FILE>) {
            next if $_ eq '';
            my @li = split(" ", $_);
            $streamList2{$li[0]} = $li[1] if !exists $streamList2{$li[0]};
        }
    }


# dont use specified streams    
    if($_[1]){ 
        my @deletedStreams = split(' ', $_[1]); 
        foreach(@deletedStreams){ 
            chomp($_);          
            delete $streamList2{$_} if exists $streamList2{$_}; 
        } 
    }

# add specified address/ports
    if($_[3]){
        my @ab = split(" ", $_[3]); 
        foreach (@ab){ 
            chomp($_); 
            $streamList2{"$_"} .= " $_"; 
        }
    }       
# not flag  
# put any unwanted screens into a hash
    my %unwanted = (); 
    if ($_[4]){
        my @values = split(' ', $_[4]); 
        foreach(@values){ 
            $unwanted{"$_"} = "$_";
        }        
    }
# only flag 
    if($_[6]){
        my $single = $_[6];
        for(keys %streamList2){ 
            delete $streamList2{$_} if $streamList2{$single} ne $streamList2{$_};
        }
    }

# number of gravs to run
    my $gravI = $_[0] or die "No value after -i";

# create hash entries in screens2 hash  with the key as an index the display
# if the display is to be skipped, skip it
    my %screens2 = ();  
    my $i = 1; #just an iterator    
        while ($i <= $gravI){
            if (exists $unwanted{$i}){           
                $i++; $gravI++;     
            }
            elsif(!exists $unwanted{$i}) {  
                $screens2{$i} = ''; $i++;
            } 
        }       
# set streams to displays
# loops down from 4 
    $i = 1; my $x = 500;
    for my $key(keys %streamList2){ 
        while($x>0){
            if(exists $screens2{$i}){
                $screens2{$i} .= "$streamList2{$key} ";
                $i++; last;
            }
            $i++; $i = 1 if $i > 4; $x--;
        }       
    }
# get rid of trailing space in screen hash left by the nested loop above
    for(keys %screens2){ chop($screens2{$_});}
    findScreens(\%screens2, $_[5]); 
}

#=findScreens===============================================
# checks to see if grav is already running on a screen with 
# the given arugments if not, it generates the command to do so
sub findScreens{
# recieve the hash from findsterams 
    my $s = shift;  my %screens = %$s; 

#recieve the cmds to be run from findgrav and if xinerama is on     
    my $cmd = findGrav(); my $option = findXsetup();    

# change resolution size    
    my $res = shift;    
    $res = 1920 if !$res or $res eq '' ;
    my($r1,$r2,$r3,$r4) = (0, $res, $res * 2, $res * 3);

# see if grav instance is running already
    my $s1 = `pgrep -fx "$cmd -sx $r1 $screens{1}"` if exists $screens{1}; 
    my $s2 = `pgrep -fx "$cmd -sx $r2 $screens{2}"` if exists $screens{2}; 
    my $s3 = `pgrep -fx "$cmd -sx $r3 $screens{3}"` if exists $screens{3}; 
    my $s4 = `pgrep -fx "$cmd -sx $r4 $screens{4}"` if exists $screens{4}; 
# account for xinerama being used   
    if($option == 0 ){
        runGrav("export DISPLAY=:0.0 && $cmd -sx $r1 $screens{1} &> /dev/null &")   if !$s1 and exists $screens{1};
        runGrav("export DISPLAY=:0.1 && $cmd -sx $r2 $screens{2} &>/dev/null &") if !$s2 and exists $screens{2};
        runGrav("export DISPLAY=:0.2 && $cmd -sx $r3 $screens{3} &>/dev/null &") if !$s3 and exists $screens{3};
        runGrav("export DISPLAY=:0.3 && $cmd -sx $r4 $screens{4} &>/dev/null &") if !$s4 and exists $screens{4};
    }
# don't use xinerama    
    elsif($option == 1){
        runGrav("export DISPLAY=:0 && $cmd -sx $r1 $screens{1} &> /dev/null &")   if !$s1 and exists $screens{1};
        runGrav("export DISPLAY=:0 && $cmd -sx $r2 $screens{2} &>/dev/null &") if !$s2 and exists $screens{2};
        runGrav("export DISPLAY=:0 && $cmd -sx $r3 $screens{3} &>/dev/null &") if !$s3 and exists $screens{3};
        runGrav("export DISPLAY=:0 && $cmd -sx $r4 $screens{4} &>/dev/null &") if !$s4 and exists $screens{4};
    }


}
# finds latest grav in /home/user/grav and uses correct arguments 
sub findGrav{
    my @gravs = `ls -a /home/user/grav | grep grav-`;   
    my $ver = $gravs[-1]; chomp($ver);
    my $cmd;

    if($ver =~ /grav-2011([0-9]{4})/){ $cmd = "./$ver -t -fs -fps 60 -am -vsr -avsr 30"; }
    else { $cmd = "./$ver -t -fs -am -avl -fps 60 -arav 30"; }
    return $cmd;
}
# might want to do more sanity checking later
# added corepooping
#example call runGrav("export DISPLAY=:0 && $cmd -sx $r1 $screens{1} &> /dev/null &") 
sub runGrav{
    checkState();   
# set hostname and check to see if there is a coredump
# if yes, move it to the date and time of creation + hostname   
    my $hname = `hostname`; chomp($hname);
    if (-e "/home/user/grav/core"){ 
        my $dat = `stat -c %z /home/user/grav/core`; my @data = split(/\s+/,$dat); 
        `mv core '$hname-$data[0]-$data[1].dump'`; 
    }
# actually run grav 
#   print "\n$_[0] \n";
    system("ulimit -c unlimited && $_[0]"); sleep 3;
}

# determines display configuration for automatic start
# this depends on "ServerLayout" as 1st section in XORG
sub findXsetup{ 
    my $option;                     # if no option for xinerama, default to 0
        my $screenNumber;                   # count number of displays
        open XORG, "</etc/X11/xorg.conf";           # get screen info by parsing xorg
        while (<XORG>){
            chomp($_);      
            if($_ =~ /EndSection/){ last; }         # only read the first section of file
                if($_ =~ /#/)         { next; }         # ignore commented lines    
                    my @input = split(/\s+/,$_);        
            if($_ =~ /Screen/){ $screenNumber++; }      # 1 indexed count of screens
                if($_ =~ /Option/){             # Find out if xinerama is on or not
                    if (($input[2] =~/"Xinerama"/) && ($input[3] =~/"1"/)){ 
                        $option = 1; return 1; 
                    }
                    else{ $option = 1; return 0; }
                }
        }
    close(XORG);
    return 0 if !$option; 
}

# sub to prevent more than 4 grav instances to start at the same time
sub checkState{
    my @instances = `pgrep grav`;
    exit 0 if scalar(@instances) >= 4;
}

# kills all instances of grav
sub killgrav{ `pkill grav`; exit 0; }

# Goes to media, sorts grav by version, 
# and updates to the largest number
sub updateGrav{
    print "Updating Grav\n";
# fetch media html and store it temporarily 
    my $derp = getstore("http://media.rc.rit.edu/gravbin/","tempfile.html");

# array to hold all matches of grav in the html and a counter to count them all 
    open(FI,"tempfile.html"); my @array; my $i = 0;
    while(<FI>){ if($_ =~ /grav-201([0-9]{5})/){ $array[$i] = $1; $i++; } } close FI;
    `rm tempfile.html`;
# largest number at end of the sorted list, then housekeeping
    @array = sort @array;
    `wget http://media.rc.rit.edu/gravbin/grav-201$array[-1] -o /home/user/grav/grav-$array[-1]`;
    `chmod 777 /home/user/grav/grav-201$array[-1]`;
    `/bin/chown user:user /home/user/grav/grav-201$array[-1]`;
    print "Grav Updated to grav-2012$array[-1]\n";
    exit 0;
}

sub help{
    print "\nHelp Menu - 12/12/2012 \n";
    print "-k        Kills ALL instances of grav\n\n";

    print "-upgrav   Updates Grav\n\n";

    print "-nodef    Does not include default streams from streams.list or streams.list. \n\n"; 

    print "-nobase	 Does not include base streams from start.pl. \n\n";

    print "-nofile   Does not include files specified in streams.list\n\n";

    print "-file 	 add streams from another file in addition to streams.list\n";
    print " 	 overrides -nofile and -nodef\n\n";

    print "-i        Specify how many instances of grav you want to run\n\n";

    print "-skip     Dont put grav on this screen number. Ordered left to right\n";
    print " 		-skip 3 for skipping third screen\n";
    print "         	-skip '2 3' using quotes to skip more than one screen\n\n";

    print "-ip      Specify specific IP/port -ip ip/port\n";
    print "         	-ip 'ip/port ip2/port2' in quotes for multiple ips\n";

    print "-not     Use default streams except for this stream. Use quotes for >1\n";
    print "    		Stream names are abbreviated as:\n";
    print "     		smfl, cis, venue, kiosk, rc, gv, rpl, biomed, gccis, carey, ih\n";

    print "-r       Set resolution width so xinerama starts on wanted screen.\n";
    print "      		-r 1920 for 1920x1080 (defaults to 1920\n";
    exit 0;
}


