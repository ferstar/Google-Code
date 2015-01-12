#!/usr/bin/perl -w
use strict;

#@author Jason Wolanyk
#@version 07232012
#script to start transcoder and create sdp file to play a stream on wowza
#automatically places sdp file in content directory
#the script does a bit of guessing if it recieves invalid params to try and make the scriptrun
#you can also specify a file with additional parameters in the form of arguments see usage
#
#@version 08152012
#checks the transcoder for running streams
#can list transcoded streams
# can do dry runs
# can kill streams
# fixed bug where auto gened stream name was just RC-/
# added option to only write sdp file or only transcode
#@version 08202012
#added transcoder options, bit rate, threads, width and height
#added line numbers to logging output
#WARRNING some functionality has not been fully tested always try a small test before using full scall
#TODO
#remove -name requirement for tcode mode
#add -v mode to send output to screen
#DVELOPERS READ THIS
# how args are parsed
# command line arguments are read in
# if a file is given it is read into @contents
# once all the values from the commandline are read in readinput() moves @contents into @ARGV
# if multible files are given the first is run and read in the rest are passed on to @contents
#this script is set up to be organized so it can be edited and updated easily, at first it was only
#going to start sdp files and other scripts would do the rest but it was easier to do them in one as
# the input was validated and there would be one place to run everything, some important standards to follow
#
#make sure that $dry is not true before you run a command that will have an effect after the script exists
# unless it wont affect the rest of the system AND dont mess with its value once its set its set
#
# if you add more varriables down the road add them to resetvars
#
#add validation to validate()
#
#read in arguments with parseargs
#
#make sure that you call dbg() to write ouput to the log atleast when you endter a function and when you leave it
#declar all uninitalized varriables
my (
	$kill,       $list,        $infile,      $dip,
	$dport,      $ip,          $sessionID,   $sessionVersion,
	$streamName, $sessionName, $port,        $fileName,
	$transcoder, $gstPath,     $contentPath, $rmtUser,
	$width,      $height,      $br,          $threads,
    	$secondaryTranscoder
);

#configure options, default values are set at start but can be changed during run
#config arguments
my $transcoder_  = "pelican-00";
my $gstPath_     = "/home/user/gst-transcode-rtp-h264.sh";
my $contentPath_ = "/mnt/icelab-videos/live/";
my $rmtUser_     = "user";

#sotres deaults for config arguments to try and fix mistakes if nessesary
$transcoder  = $transcoder_;
$gstPath     = $gstPath_;
$contentPath = $contentPath_;
$rmtUser     = $rmtUser_;

#initalizes all modes to false
my $tcode = 0;
my $sdp   = 0;
my $dry   = 0;

#varriables for holding data used by this script but not nessesary
#to actually run the transcoder or create sdp files
my @contents;
my %streams;
my $lastip; #store ip for last ip to make multiple streams from single ip easier
my $dbgcnt = 0;

#open log file so if something goes wrong we can look into it
my $logname = "logs/streamLive.logs/streamLive.log-" . time();
open( LOG, ">", $logname )
  or print STDERR "logging file inescessable";

# sent to stderr to prevent issues when called by another script
print STDERR "LOG IS $logname\n";
print STDERR "Params are @ARGV\n";

#a function for debugging, prints messages out to log file
sub dbg($$) {

    print "DEBUG: $_[0] #$dbgcnt\n";
    if (!defined($_[1])){$_[1]="";}
    print LOG "#$dbgcnt: $_[0] \t\t".(caller())[2]."\n";
    $dbgcnt++;
}

#clears all varriables
sub resetvars() {
	&dbg("start resetvars");
	(
		$kill,       $list,        $infile,      $dip,
		$dport,      $ip,          $sessionID,   $sessionVersion,
		$streamName, $sessionName, $port,        $fileName,
		$transcoder, $gstPath,     $contentPath, $rmtUser,
		$width,      $height,      $br,          $threads,
        $secondaryTranscoder
	  )
	  = "";
	&dbg("done resetvars");
}

#prints out help message
sub usage() {
	print "
	THIS SCRIPT SHOULD BE RUN AS ROOT ON THE WOWZA SERVER
	
	This script takes in the ip and port of a RTP H264/AAC stream
	and passes it through a transcoder. It is designed to be run as part
	of a web site where it is more important that the stream gets started thant
	that it is started the way the user specifies so it has several fallbacks
	to ensure that when a stream is requested it get started. 
	
	It can also read a file with the -f option, each line in the file
	is read as $0 params where params is a line in the file the params 
	are then processed as if they were from the cli.
	
	If params are not specified and clear is not used some parameters
	may be reused ex if you have 3 streams on 192.168.1.1 /1000 /2000 /3000
	you coud specify
	192.168.1.1/1000
	-port 2000
	-port 3000
	and all 3 would be started  
	 
	 KILL WILL CARY OVER BETWEEN RUNS
	List sorce ip and port first other than that order does not matter
	$0 -file (-ip -port | ip/port )  [(-dip -dport | dip/dport )] 
		[-id][-vers][-session][-transcoder] [-dry] [-sdp] [-tcode]
		[-content] [-gstpath] [-f] [-list] [-width] [-height] [-br]
		[-threads]
		 
	$0 -list
	
	
	REQUIRED PARAMS
	-ip		ip address to receive stream from
	-port 	port to listen for ip on
	-file 	what you want the sdp file to be called 
				(file will print to stdout if none is specified)
	MODE
		the script can be called in several modes, by default it runs both -sdp and -tcode
		-sdp 		write the sdp file only
		-tcode		start transcoding the stream
		-dry 		runs the script but does not crate files or start transcoder
					good for debugging and testing. overides -sdp and -tcode
		-kill	kill the stream specified by ip/port and dip/dport 
					both sets of ips must be given
		-list	Shows all streams running on the transcoder		
	
	OPTIONAL SDP PARAMS	
		-dip		specify destination ip transcoder will send to
						default: same as source port
		-dport		specify destination port transcoder will send to
						default: source port +2
		-id			unique session id
		-vers		session version
		-stream 	what you want your stream to be called
		-session	what you want the session to be called
	OPTIONAL TRANSCODER PARAMS
		-width 		the width of the stream 0 for default
		-height		the height of the stream 0 for default
		-br			bitrate of stream 0 for default
		-thread		number of threads to use 0 for default
	OPTIONAL CONFIG PARAMS
		-transcoder change the transcoder server 
						will revert to default if not found 
		-content	change where sdp file is saved
		-gstpath	change where the transcoder script is
						will write the script in location if it
						does not exist
		-as 		the user you want to ssh as
	OPTINAL FILE PARAMS
	-f 			read in additional arguments from given file
	-clear		for files clears any varriables from last run 
				OR PREVIOUSLY SPECIFIED IN CURRENT RUN 
				
	WARRNING some functionality has not been fully tested always try a small test before using full scale, -dry can be useful
	\n";
	exit 0;
}

#reads in arguments, the arguments array can be generated from commandline or from a file
sub parseargs() {
	&dbg("start parseargs");
	while (@ARGV) {
		$_ = shift(@ARGV);
		chomp($_);
		if ( $_ eq '-ip' ) {
			if ( !$ip ) { $ip = shift @ARGV; }
			else { $dip = shift @ARGV; }
		}
		elsif ( $_ eq '-dry' )   { $dry   = 1; }
		elsif ( $_ eq '-kill' )  { $kill  = 1; }
		elsif ( $_ eq '-list' )  { $list  = 1; }
		elsif ( $_ eq '-sdp' )   { $sdp   = 1; }
		elsif ( $_ eq '-tcode' ) { $tcode = 1; }
		elsif ( $_ eq '-port' )  {
			if ( !$port ) { $port = shift @ARGV; }
			else { $dport = shift @ARGV; }
		}
		elsif ( $_ eq '-clear' ) { &resetvars(); }
		elsif ( $_ eq '-f' && !@contents ) {

   #if the param comes across -f and no other file has been read into contents
   #then read it in to the contents array, which is a buffer that holds the data
   #so it isnt lost when the program resets for the next run
			$infile = shift @ARGV;
			&dbg("reading in the file");
			open( INPUT, "<", $infile )
			  or die("unable to read file $infile");
			@contents = <INPUT>;
			&dbg("@contents\n...done reading file");
			close(INPUT);
			$infile = "";
		}
		elsif ( $_ eq '-f' && @contents ) {
			push( @contents, "-f " . shift(@ARGV) );
		}
		elsif ( $_ eq '-gstpath' )    { $gstPath        = shift @ARGV; }
		elsif ( $_ eq '-content' )    { $contentPath    = shift @ARGV; }
		elsif ( $_ eq '-transcoder' ) 
            { 
                        $transcoder     = shift @ARGV; 
            }
		elsif ( $_ eq '-dip' )        { $dip            = shift @ARGV; }
		elsif ( $_ eq '-dport' )      { $dport          = shift @ARGV; }
		elsif ( $_ eq '-file' )       { $fileName       = shift @ARGV; }
		elsif ( $_ eq '-id' )         { $sessionID      = shift @ARGV; }
		elsif ( $_ eq '-vers' )       { $sessionVersion = shift @ARGV; }
		elsif ( $_ eq '-stream' )     { $streamName     = shift @ARGV; }
		elsif ( $_ eq '-session' )    { $sessionName    = shift @ARGV; }
		elsif ( $_ =~ m/--?[h|help]$/i ) { &usage(); }
		elsif (
			$_ =~ m/^	
			(
				(25{1}[0-5] #match 250-255
				|2[0-4]\d	#match 200-249
				|[0-1]?\d\d #match 099-199
				| \d?\d)	#match 0-99	
				\.			#match a . 
			){3}			#repeat 3 times
			(
				25{1}[0-5] #match 250-255
				|2[0-4]\d	#match 200-249
				|[0-1]?\d\d #match 099-199
				| \d?\d		#match 0-99
			)				#once more without the .
			\/				#match a slash
				#match port
			(
			6553[0-5]		#65530-65535
			|655[0-2]\d		#65500-65529
			|65[0-4]\d\d	#65000-65499
			|64\d\d\d		#64000-64999
			|6[0-3]\d\d\d	#60000-63999
			|[0-5]\d\d\d\d	#00000-59999
			|\d\d\d\d		#0000-9999
			|\d\d\d			#000-999
			|\d\d			#00-99
			|\d				#0-9
			)
			$/x
		  )    # end match at end of line, ignore whitespace in regex
		{
			if ( !$ip || !$port ) { ( $ip, $port ) = split( '/', $_ ); }
			else { ( $dip, $dport ) = split( '/', $_ ); }
		}
		elsif ( $_ eq '-width' ) {
			$width = shift @ARGV;
			if ($width) { $width = '-width ' . $width; }
			else { $width = ""; }
		}
		elsif ( $_ eq '-height' ) {
			$height = shift @ARGV;
			if ($height) { $height = '-height ' . $height; }
			else { $height = ""; }
		}
		elsif ( $_ eq '-br' ) {
			$br = shift @ARGV;
			if ($br) { $br = '-br ' . $br; }
			else { $br = ""; }
		}
		elsif ( $_ eq '-threads' ) {
			$threads = shift @ARGV;
			if ($threads) { $threads = '-threads ' . $threads; }
			else { $threads = ""; }
		}
		else {
			print STDERR "unknown parameter $_\n";
			&dbg("unknown parameter $_");
		}
	}
	if ( !$sdp && !$tcode && !$kill ) {
		&dbg("nomode set running sdp and tcode");
		$sdp   = 1;
		$tcode = 1;
	}
	&dbg("done parsargs");
}

#check if ip is valid returns true if it is
sub chkip($) {
	&dbg("startchkip");
	if (
		!$_[0]
		|| $_[0] !~ m/^ #a regex to match an ip	
		(
			(25{1}[0-5] #match 250-255
			|2[0-4]\d	#match 200-249
			|[0-1]?\d\d #match 099-199
			| \d?\d)	#match 0-99	
			\.			#match a . 
		){3}			#repeat 3 times
		(
			25{1}[0-5] #match 250-255
			|2[0-4]\d	#match 200-249
			|[0-1]?\d\d #match 099-199
			| \d?\d		#match 0-99
		)				#once more without the .
		$/x
	  )    # end match at end of line, ignore whitespace in regex
	{
		&dbg("done chkip 0");
		return 0;
	}
	else {
		&dbg("done chkip 1 ");
		return 1;
	}
}

#retruns true if given valid port number
sub chkport($) {
	&dbg("start chkport");
	if (
		!$_[0] || $_[0] !~    #matches a port number
		m/^
		6553[0-5]		#65530-65535
		|655[0-2]\d		#65500-65529
		|65[0-4]\d\d	#65000-65499
		|64\d\d\d		#64000-64999
		|6[0-3]\d\d\d	#60000-63999
		|[0-5]\d\d\d\d	#00000-59999
		|\d\d\d\d		#0000-9999
		|\d\d\d			#000-999
		|\d\d			#00-99
		|\d				#0-9
		$/x
	  )
	{
		&dbg("end chkport 0");
		return 0;
	}
	else {
		&dbg("end chkport 1");
		return 1;
	}
}

sub validate() {
	&dbg("start validate");
	if ( !$ip ) { $ip = $lastip; }
	if ( !&chkip($ip) ) {
		if ( !defined $ip ) { $ip = "no ip given" }
		print STDERR "Invalid IP $ip going to next\n";
		&dbg("Invalid IP $ip going to next");
		return 0;
	}
	&dbg("ip $ip ok");
	if ( !&chkip($dip) ) {
		print STDERR "destip invalid defaulting to source ip\n";
		&dbg("destip invalid defaulting to source ip");
		$dip = $ip;
	}
	&dbg("dip $dip ok");
	chkport($port) or die "invalid Source port\n";
	&dbg("port $port ok");
	if ( !&chkport($dport) ) {
		print STDERR "invalid Dest port defaulting to source port +2\n";
		&dbg("invalid Dest port defaulting to source port +2");
		$dport = $port + 2;
	}
	&dbg("dport $dport ok");

	#if an argument is not given but is needed and can be generated it is
	if ( !defined $streamName )     { $streamName     = "RC-$ip/$port"; }
	if ( !defined $sessionID )      { $sessionID      = time(); }
	if ( !defined $sessionVersion ) { $sessionVersion = time(); }
	if ( !defined $sessionName )    { $sessionName    = "RC-" . time(); }
	if ( !defined $width )          { $width          = ""; }
	if ( !defined $height )         { $height         = ""; }
	if ( !defined $br )             { $br             = ""; }
	if ( !defined $threads )        { $threads        = ""; }

	&dbg("done validate");
}

#creates and writes the sdp file for the script
sub gensdp() {
	&dbg("startgensdp");

	#generates the sdp file
	my $output = "v=0
	o=- $sessionID $sessionVersion IN IP4 $streamName
	s=$sessionName
	i=N/A
	c=IN IP4 $dip/255
	t=0 0
	m=video $dport RTP 96
	b=AS:500
	a=rtpmap:96 H264/90000
	";
	&dbg("made sdp file $output");

	#write sdp file
	if ($fileName) {
		if ( $fileName !~ m/^.*\.sdp/ ) { $fileName .= ".sdp"; }
		&dbg("writing to file $contentPath$fileName");
		if ( !$dry ) {
			open( FILE, ">", $contentPath . $fileName )
			  or print STDERR "unable to open file $contentPath$fileName"
			  and &dbg("ERR unable to open file $contentPath$fileName")
			  and return 0;
			print FILE $output;
		}
		else { &dbg("skipped writing file") }
		close FILE;
		&dbg("done closed $contentPath.$fileName");
	}
	else {
		&dbg("no file name specified");
		print STDERR "no file name specified";
		return 0;
	}
	&dbg("done gensdp");
	return 1;
}

#logs on to the transcoding server and checks what streams are running
#this only works for the gst-transcode script
sub checkrunning() {
	&dbg("starting checkrunning");

	#ask transcoder for all running pipes
	my @output =
	  `ssh user\@$transcoder 'ps aux | grep gst-launch | grep -v grep'`;
	&dbg("transcoding server replied START @output DONE");

	#process each pipe
	foreach my $line (@output) {

		#varriables for info wanted from teh pipe
		my @data     = [];
		my $destip   = "";
		my $destport = "";
		my $srcip    = "";
		my $srcport  = "";
		my $pid      = "";
		my $tname    = "";
		$line =~ tr/ */ /s;    #remove duplicate spaces
		@data = split( / /, $line );       #split on spaces
		$pid  = $data[1];
		@data = grep( !/.*!.*/, @data );
		my $type = "";                     # stores wether processing a
		&dbg("processing @data");

		#loop through each item in the pipe
		#the script stores what type of element it is in and
		#pulls info from it and stores it based on which type
		#of element it pulled the data from
		#some elements have 2 ports for rtp and rtpc rtp is specified first
		# so only the first one is used
		foreach (@data) {
			if ( $_ eq "udpsink" ) {
				$type = "sink";
			}
			elsif ( $_ eq "udpsrc" ) {
				$type = "src";
			}
			elsif ( $type eq "src" ) {
				if ( $_ =~ m/port=/ && !$srcport ) {
					$srcport = substr( $_, 5 );
				}
				if ( $_ =~ m/multicast-group=/ && !$srcip ) {
					$srcip = substr( $_, 16 );
				}
			}
			elsif ( $type eq "sink" ) {
				if ( $_ =~ /host=/ && !$destip ) {
					$destip = substr( $_, 5 );
				}
				if ( $_ =~ m/port=/ && !$destport ) {
					$destport = substr( $_, 5 );
				}
			}
			elsif ( $_ =~ m/name=\(string\).*/ ) {
				$tname = substr( $_, 13 );
			}
		}

		#info on streams is stored in a hash
		#streams can have the same name but there is no point in 2 streams
		#with the same src/dest ip and port
		$streams{"$srcip/$srcport-$destip/$destport"} = [ $pid, $tname ];
		&dbg("detected stream $srcip/$srcport-$destip/$destport, $pid, $tname");
	}
	&dbg("done check running");
}

#start transcoding server
#@return
#3 dryrun not starting
#2 transcoder is already running
#1 had to revert to default
#0 failed to start
sub transcode() {
	&dbg("started running transcode");
	if ( exists $streams{"$ip/$port-$dip/$dport"} ) {
		print "transcoder already running on $transcoder\n";
		return 2;
	}
	my $param = "-sip $ip -dip $dip -sport $port -dport $dport -name $streamName $height $width $br $threads 1>/dev/null 2>/dev/null &";
	&dbg("going to run ssh $rmtUser\@$transcoder \"$gstPath $param\" ");
	if ($dry) {
		&dbg("not starting transcoder dry run");
		return 3;
	}
	my $out = `ssh $rmtUser\@$transcoder \"$gstPath $param\" 2>&1`;
	if ( $out =~ /No such file or directory$/ && $gstPath ne $gstPath_ ) {
		print STDERR "unable to find file trying default\n";
		&dbg("ERR unable to find file trying default\n");
		$out = `ssh $rmtUser\@$transcoder \"$gstPath_ $param 1>/dev/null &\"`;
		if ( $out =~ /No such file or directory$/ ) {
			print STDERR "unable to find default file either\n";
			&dbg("ERR unable to find default file either\n");
			return 0;    #transcoder failed to start file missing
		}
		else {
			&dbg("done transcode default worked 1");
			return 1;
		}    #custom script failed to start but default was found
	}
	elsif ( $out =~ /No such file or directory$/ ) {
		print STDERR "unable to find file";
		&dbg("ERR unable to find default file\n");
		return 0;    #transcoder script not found
	}
	&dbg("SSH returned $out\n");
	return 1;
}

#puts @contents into @ARGV for nextrun
#returns true if more data was read in
sub readinput() {
	&dbg("start readinput");
	if (@contents)    #load args for next run
	{
		chomp $contents[0];

		#pulls a line from contents to be used as @ARGV
		@ARGV = split( / /, $contents[0] );
		chomp @ARGV;
		&dbg( "readinput read $contents[0] as " . join( ':', @ARGV ) );
		shift(@contents);
		return 1;
	}
	else {
		&dbg("no input files were given");
		return 0;
	}
	print STDERR "readfile reached unreachable";
	&dbg("you divided by zero");
	return 0;
}

#main portion of the script
sub main() {
	if ( !@ARGV ) { &usage(); }

	#loop through arguments
	while (@ARGV) {
		sleep 1;    #sleep 1 sec between each run.
		   #reset vars that must be unique theses values can be overridden later
		&dbg("resetting\n----------------\n");

		#vars that must be set by user
		$fileName = "";
		$port     = "";
		$ip       = "";
		$list     = "";

		#fixes issue where a leftover ip
		#causes new ip to be set to dest ip
		$lastip = $ip;

		#find which streams are currently running
		&checkrunning();

		#now that everything is ready begin running
		&dbg("Starting args are @ARGV parsing...");
		&parseargs();    #read in args from ARGV, clearing it
		&dbg("...args parsed");
		&readinput();    #read data from any given files into @ARGV
		&dbg("read file new args are @ARGV");

		#done processing input
		#print which streams are running if requested
		if ($list) {
			foreach ( keys %streams ) {
				print "$_ $streams{$_}[0] $streams{$_}[1]\n";
			}
		}
		&validate() or next;    #validate args and fill in optional args
		&dbg("validated");
		if ($kill) {
			print "target $ip/$port-$dip/$dport\n";
			&dbg("told to kill stream $ip $port $dip $dport");
			if ( exists $streams{"$ip/$port-$dip/$dport"} ) {
				my $killcmd = "kill -9 " . $streams{"$ip/$port-$dip/$dport"}[0];
				print "kill ouput is ssh user\@$transcoder $killcmd\n";
				&dbg("kill ouput is ssh user\@$transcoder $killcmd\n");
				if ( !$dry ) {
					my $output = `ssh user\@$transcoder $killcmd 2>&1`;
					print "transcoder kill output $output\n";
					&dbg("transcoder kill output $output\n");
				}
			}
			else { print "Target stream is not running\n";}
			next; #prevents a stream from being started right after being killed
		}
		if ($sdp) { &gensdp() or &dbg('failed to gen sdp') and  next; }    #creats the sdp file and saves it
		&dbg("done with sdp section");
		if ($tcode) 
        {
            if ( ! &transcode() && defined $secondaryTranscoder)
            {
                $transcoder=$secondaryTranscoder;
                &transcode() or next;
            }
         }    #start transcoding
		&dbg("done with transcode section");
		&dbg("done with run \n-----------------\n");
	}    #loops as log as args are provided by cli or readfile()
}
&main();
print "execution of $0 complete!\n";
exit 0;
