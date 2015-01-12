#!/usr/bin/perl -w
use strict;

#@author Jason Wolanyk
#@version 08152012
#this script scans the queue directory for any files and then starts streams based on params
#contained in files with the same name in streams. It also checks the files in queue to kill
#streams that have been running idle for too long and stops any unknown streams.
# the amount of time between checks and how long a stream is idle are all configurealble
#
#dir to check for streams to start
#TODO if a file does not exist in streams remove it in queue
my $queue = "/var/www/html/queue";

# dir where stream params are stored
my $streams = "/var/www/stream-ctl/streams";

#number of sec a stream can be idle before it is stoped.
#Made very long per request of Gurcharan for now 
my $timeout = 600000;

#number of seconds between checks of streams
my $delay = 5;

#logfile where logs are saved
open( LOG, ">", "logs/log-transcodeManager.log" )  or print STDERR "unable to open log \n";
#for debuging send log to stdout
#my $stdout = *STDOUT;
#open( LOG, ">", $stdout ) or die("failed");
#*LOG = *STDOUT;
#unlink($stdout);

#END
#{
#	print "endblock closing handles";
#	close(LOG);
#	unlink($stdout);
#	
#}

#hash of streams that have been started by this script
my %started;
my $params;
my @files;
my @output;
print "starting\n";
print LOG "$0 started\n";

my $running = "tcodemgr-$$";
open(X,">",$running)or print LOG "could not open running file\n";
close(X);
while (-e $running)
{
    print LOG "checking -----".join(":",(localtime(time))[5,-2, 2, 1, 0])."\n";
	@files = <$queue/*>;
	print LOG"read " . scalar(@files) . " files\n";
	
    foreach my $file (@files)
	{
		print LOG"\tread $file \n";

		#get the file name and skip . and ..
		$_ = ( split( /\//, $file ) )[-1];
		if ( $_ =~ m/^\..*$/ ) { next; }
		
		print LOG "\t\tname is $_ mod time ".(( time() ) - (( stat("$queue/$_") )[9]))."\n";
		
		$params = "-file $_ -f $streams/$_ 2>&1";
		
		if ( ( ( time() ) - ( stat("$queue/$_") )[9] ) > $timeout )
		{
			#kill the stream if no one is watchin it
			print LOG"\t\tkilling $_\n";
			print LOG"\t\trunning ./streamLive.pl -kill $params\n";
			@output=`./streamLive.pl -kill $params`;
			foreach (@output)
			{
				print LOG "\t\t\t $_";
			}
	
    		print "\n";
			unlink("$queue/$_");
			if ( defined $started{$_} )
            {
                 delete( $started{$_} ); 
            }
	
    		print LOG"\t\tdone\n";
		}
		elsif ( defined $started{$_} )
		{
			# if a script has been in the queue for a bit it has
			# probably already been started, dont waste time
			# checking it
			print LOG"\t\t$_ already started\n";
		}
		else
		{
			#start transcoding the streams, streamLive will chekc if its running
			print LOG"\t\tprepping $_\n";
			print LOG"\t\trunning ./streamLive.pl -tcode $params \n";
			@output=`./streamLive.pl -tcode $params`;
			foreach (@output){print LOG "\t\t\t $_\n";}
			if ( !defined $started{$_} ) { $started{$_} = 1; }
			print LOG"\t\tdone\n";
		}
		print LOG"\tfinished reading file \n";
	}
	print LOG"checking for missed streams\n";
	
    #look at what streams have been started and what streams are in the queue
	# if a stream is started but its file is not found kill it
	foreach ( keys %started )
	{
		unless($started{$_}==1){next;}
		if ( ! -e "$queue/$_" )
		{
			print LOG"\t$queue/$_ not found \n";
			$params = "-file $_ -f $streams/$_";

			#kill the stream if no one is watchin it
			print LOG"\tkilling missed stream $_ started is $started{$_}\n";
			print LOG"\trunning ./streamLive.pl -kill $params\n";
			@output=`./streamLive.pl -kill $params`;
			foreach (@output){print LOG "\t\t\t $_\n";}
			#remove the stream from the queue and started hash 
			unlink("$queue/$_");
			if ( defined $started{$_} && $started{$_}==1 ) { delete( $started{$_} ); }
			print LOG"\tdone\n";
		}
	}
	print LOG"check complete-----\n\n";
	print LOG"waiting\n\n";
	sleep $delay;
}
print "done\n";
print LOG"execution of $0 ended\n";
END { 
	if (-e $running){print LOG "recieved kill signal\n";}
	print LOG "closing log\n";
	close(LOG); 
}
