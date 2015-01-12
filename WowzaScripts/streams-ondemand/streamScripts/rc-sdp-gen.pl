#!/usr/bin/perl -w
use strict;
sub usage()
{
	print <<"	END"
	$0 (-ip -port | ip/port name) [-file] [-id][-vers][-name][-session]
	Order of params does not matter
	
	REQUIRED PARAMS
	-ip		ip address to receive stream from
	-port 	port to listen for ip on
	-file 	what you want the sdp file to be called 
				(file will print to stdout if none is specified)
	
	OPTIONAL PARAMS	
	-id			unique session id
	-vers		session version
	-stream 	what you want your stream to be called
	-session	what you want the session to be called
	END
;
	exit 0;
}
my($ip, $sessionID, $sessionVersion,$streamName,$sessionName,$port,$fileName );

while (@ARGV)
{
	$_=shift(@ARGV);
	if ($_ eq '-ip'){$ip=shift @ARGV;next;}
	elsif ($_ eq '-port'){$port=shift @ARGV;next;}
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
			($ip,$port)=split('/',$_);
		} 
	else{print STDERR "unknown parameter $_\n";}
}

#check if ip is valid
if (!$ip || $ip !~ 	
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
		die("$0: Invalid IP\n");	
	}

#check if port is valid
if (!$port || $port <1||$port >65535)
	{
		die("$0: Invalid port");
	}

#sets varriable to defaults if they are not set
if(!$sessionID){$sessionID=time();}
if(!$sessionVersion){$sessionVersion=time();}
if(!$streamName){$streamName="RC\@$ip/$port";}
if(!$sessionName){$sessionName="RC-".time();}

#generates the sdp file
my $output="v=0
o=- $sessionID $sessionVersion IN IP4 $streamName
s=$sessionName
i=N/A
c=IN IP4 $ip/255
t=0 0
m=video $port RTP 96
b=AS:500
a=rtpmap:96 H264/90000
";

my $isopen=0;
if ($fileName)
{
	if($fileName !~ m/^.*\.sdp/){$fileName.=".sdp"}
	open (FILE,">",$fileName)
		or $isopen=1;
}
else{$isopen=2;}

if (!$isopen){print FILE $output;}
elsif ($isopen==1) 
{
	print $output;
	print STDERR "a=unable to openfile\n";
}
else {print $output;}

exit 0;
