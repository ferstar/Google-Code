#!/usr/bin/perl -w
use strict;

#script to start transcoder and create sdp file to play a stream on wowza
#automatically places sdp file in content directory 
#the script does a bit of guessing if it recieves invalid params to try and make the scriptrun
#you can also specify a file with additional parameters in the form of arguments see usage
#WARRNING some functionality has not been fully tested always try a small test before using full scall
 
#@author Jason Wolanyk
#@version 07232012

my $transcoder_="pelican-00.rit.edu";
my $gstPath_="/home/user/gst-transcode-rtp-h264.sh";
my $contentPath_="/mnt/icelab-videos/live/";
my $rmtUser_="user";
my($infile, $dip, $dport, $ip, $sessionID, $sessionVersion,$streamName,$sessionName,$port,$fileName, $transcoder, $gstPath, $contentPath, $rmtUser);
my @contents;
my $lastip;#store ip for last ip to make multiple streams from single ip easier

$transcoder=$transcoder_;
$gstPath=$gstPath_;
$contentPath=$contentPath_;
$rmtUser=$rmtUser_;

my $dbgcnt=0;

open (DBG,">","debug.txt")or print STDERR "debugging file inescessable";
sub dbg($)
{
	#print "DEBUG: $_[0] #$dbgcnt\n";
	print DBG "#$dbgcnt: $_[0] \n";
	$dbgcnt++;
}

sub resetvars()#clears varriables
{
	($infile, $dip, $dport, $ip, $sessionID, $sessionVersion,$streamName,$sessionName,$port,$fileName, $transcoder, $gstPath, $contentPath, $rmtUser)="";
}

sub usage()
{
	print "
	THIS SCRIPT SHOULD BE RUN AS ROOT ON THE WOWZA SERVER
	
	This script takes in the ip and port of a RTP H264/AAC stream
	and passes it through a transcoder
	
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
	
	$0 -file (-ip -port | ip/port )  [(-dip -dport | dip/dport )] 
		[-id][-vers][-session][-transcoder]
		[-content] [-gstpath] [-f]
	list sorce ip and port first
	
	REQUIRED PARAMS
	-ip		ip address to receive stream from
	-port 	port to listen for ip on
	-file 	what you want the sdp file to be called 
				(file will print to stdout if none is specified)
	
	OPTIONAL PARAMS	
	-dip		specify destination ip transcoder will send to
					default: same as source port
	-dport		specify destination port transcoder will send to
					default: source port +2
	-id			unique session id
	-vers		session version
	-stream 	what you want your stream to be called
	-session	what you want the session to be called
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
				
	WARRNING some functionality has not been fully tested always try a small test before using full scall
	\n";
	exit 0;
}

sub parseargs()
{
	while (@ARGV)
	{
		$_=shift(@ARGV);
		chomp($_);
		if ($_ eq '-ip')
			{
				
				if(!$ip){$ip=shift @ARGV;}
				else {$dip=shift @ARGV;}
				next;
			}
		elsif ($_ eq '-port')
		{
			if(!$port){$port=shift @ARGV;}
			else {$dport=shift @ARGV;}
			next;
		}
		elsif ($_ eq '-clear'){&resetvars();next;}
		#if the param comes across -f and no other file has been read into contents
		elsif ($_ eq '-f' && ! @contents ) 
		{
			$infile=shift @ARGV;
			&dbg("reading in the file");
			open(INPUT,"<",$infile) or die("unable to read file");
			@contents=<INPUT>;
			&dbg("@contents\n...done reading file");
			
			close(INPUT);
			$infile="";
			next;
		}
		elsif ($_ eq '-gstpath'){$gstPath=shift @ARGV; next;}
		elsif ($_ eq '-content'){$contentPath=shift @ARGV; next;}
		elsif ($_ eq '-transcoder'){$transcoder=shift@ARGV; next;}
		elsif ($_ eq '-dip'){$dip=shift @ARGV; next;}
		elsif ($_ eq '-dport'){$dport=shift @ARGV; next;}
		elsif ($_ eq '-file'){$fileName=shift @ARGV;next;}
		elsif ($_ eq '-id'){$sessionID=shift @ARGV;next;}
		elsif ($_ eq '-vers'){$sessionVersion=shift @ARGV;next;}
		elsif ($_ eq '-stream'){$streamName=shift @ARGV;next;}
		elsif ($_ eq '-session'){$sessionName=shift @ARGV;next;}
		elsif ($_ =~ m/--?[h|help]/i){&usage();}
		elsif($_ =~ m/^	
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
			$/x) 			# end match at end of line, ignore whitespace in regex
			{
				if(!$ip || !$port){($ip,$port)=split('/',$_);}
				else{($dip,$dport)=split('/',$_);}
				next;
			} 
		else{print STDERR "unknown parameter $_\n";}
	}
}

#check if ip is valid
sub chkip($)
{
	if (!$_[0] || $_[0] !~ 	
		m/^	
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
		$/x) 			# end match at end of line, ignore whitespace in regex
		{
			return 0;	
		}
	else {return 1;	}
}

#retruns true if given valid port number
sub chkport($)
{
	if (!$_[0] || $_[0] !~ #matches a port number
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
			return 0;
		}
	else {return 1;}
}

sub validate()
{
	&dbg("validating");
	if (!$ip){$ip=$lastip;}
	if (!&chkip($ip))
	{
		print STDERR "Invalid IP $ip going to next\n";
		&dbg("Invalid IP $ip going to next");
		return 0;
	} 
	&dbg("ip $ip ok");
	if (!&chkip($dip))
	{
		print STDERR "destip invalid defaulting to source ip\n";
		&dbg("destip invalid defaulting to source ip");
		$dip=$ip;
	}
	&dbg("dip $dip ok");
	
	chkport($port) or die "invalid Source port\n";
	&dbg("port $port ok");
	if(!&chkport($dport))
	{
		print STDERR "invalid Dest port defaulting to source port +2\n";
		&dbg("invalid Dest port defaulting to source port +2");
		$dport=$port+2;
	} 
	
	&dbg("dport $dport ok");
	&dbg("done validating");
}

sub gensdp()
{
	&dbg("generating sdp file");
	#generates the sdp file
	my $output="v=0
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
	if ($fileName)
	{
		if($fileName !~ m/^.*\.sdp/){$fileName.=".sdp";}
		&dbg("writing to file $contentPath.$fileName");
		open (FILE,">",$contentPath.$fileName)
			or print STDERR "unable to open file $contentPath$fileName"
				and return 0;
		print FILE $output;
		close FILE;
		&dbg("done closed $contentPath.$fileName");
	}
	else
	{
		&dbg("no file name specified");
		print STDERR "no file name specified";
		return 0;
	}
	return 1;
}

#start transcodingserver
sub transcode()
{
	my $param="-sip $ip -dip $dip -sport $port -dport $dport -name $streamName 1>/dev/null &";
	&dbg("going to run ssh $rmtUser\@$transcoder $gstPath $param ");
	my $out=`ssh $rmtUser\@$transcoder $gstPath $param `;
	if ($out =~ /No such file or directory$/&& $gstPath ne $gstPath_)
	{
		print STDERR "unable to find file trying default\n";
		$out=`ssh $rmtUser\@$transcoder \"$gstPath_ $param 1>/dev/null &\"`;
		if ($out =~ /No such file or directory$/){print STDERR "unable to find default file either\n";}
		else {return 1;}
	}
	elsif ($out =~ /No such file or directory$/){print STDERR "unable to find file";}
	
	print "SSH returned $out\n";
}

sub readinput()
{
	
	if (@contents)#load args for next run
	{
		chomp $contents[0];
		@ARGV=split(/ /, $contents[0]);#pulls a line from contents to be used as @ARGV
		chomp @ARGV;
		&dbg("readinput read $contents[0] as ".join(':',@ARGV));
		shift(@contents);
		return 1;
	}
	else{return 0;}
	print STDERR "readfile reached unreachable";
	return 0;
}



while (@ARGV)
{
	sleep 1;#sleep 1 sec between each run.
	#reset vars that must be unique theses values can be overridden later
	&dbg("resetting\n----------------\n");
	#vars that must be set by user
	$fileName="";
	$port="";
	$lastip=$ip;#fixes issue where a leftover ip causes new ip to be set to dest ip
	$ip="";
	#vars that can be auto gened
	$sessionID=time();
	$sessionVersion=time();
	$sessionName="RC-".time();
	$streamName="RC-$ip/$port";
	
	&dbg("Starting args are @ARGV parsing...");
	&parseargs();#read in args
	&dbg("...args parsed");
	&readinput(); #read the file and/or
	&dbg("read file new args are @ARGV"); 
	&validate() or next;#validate args and fill in optional args
	&dbg("validated");
	&gensdp()or next;#creats the sdp file and saves it
	&dbg("wrote sdp file");
	&transcode()or next;#start transcoding
	&dbg("transcoded");
	&dbg("done with run \n-----------------\n")
} #loops as log as args are provided by cli or readfile()

print "execution of $0 complete!\n";

exit 0;
#TODO start stream manager 
#stream manager site calls from webpage'addstream.html?uuid='+uuid+'&vhost='+escape(vhostName)+'&appName='+escape(applicationName), 575, 250, null, true)
