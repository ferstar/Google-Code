#! /usr/bin/perl

use warnings;
use strict;

my $datafile = "bridges.dat";
open(FILE,"<",$datafile) or die "Could not open bridges.dat file; does it exist?";

# Program usage
my $usage = "[status|stop|start|help]";

# Set up some variables for the program to use
my $bridge->{exec} = "/usr/bin/QuickBridge";
$bridge->{options} = "-t 127 -s 600";
$bridge->{logdir} = "/var/log/bridge";
my $screen = "/usr/bin/screen";

# Read through the data file of bridge information that we are given
# and send the information off to createBridge to start the process
sub readFile {
	my @bridges;

	while (my $line = <FILE>) {
		chomp $line;
		
		if ($line =~ /^$/ || $line =~ /^[\t\s#]/) { next; }

		# Split up the input line into three arguments. The arguments are:
		# <Multicast Address>	<Multicast IP>	<Unicast IP>
		my @array = split(/\t+/,$line);
	
		push(@bridges, [@array]);
	}
	close(FILE);

	return @bridges;
}

# This sub is used by the status sub and is what is actually used to perform the processing and return
# the status of a running or stopped bridge
sub getStatus {
	# 0 - Stopped
	# 1 - Running
	my $ret = 0;
	
	my $uniport = shift;

	my @procstatus = `ps -ef|grep $uniport`;
	if(scalar(@procstatus) > 2) { $ret = 1;}
		else { }

	return $ret;
}

# Return the status of all of the currently-running bridges by using the shortname
# that has been defined in the data file being read in
sub status {
	shift;

        printf "%-16s%-24s%-20s\n","Unicast IP","Bridge","Status";

	my @bridges = readFile();
	if (@_ > 0) {
		foreach my $item (@_) {
			my @row = split(/\t+/,`cat $datafile|grep $item`);
			if (@row < 1) { } else {
				my $val = getStatus($item);
				if ($val == 1) {printf "%-16s%-24s%-20s\n",$row[2],$row[3],"Running";}
				else { printf "%-16s%-24s%-20s\n",$row[2],$row[3],"Stopped"; }
			}
		}
	} else {
		foreach my $row (0..(@bridges-1)) {
			my $val2 = getStatus($bridges[$row][2]);
			if ($val2 == 1) {printf "%-16s%-24s%-20s\n",$bridges[$row][2],$bridges[$row][3],"Running";}
			else { printf "%-16s%-24s%-20s\n",$bridges[$row][2],$bridges[$row][3],"Stopped"; }
	        }
	}

	exit 0;
}

# Start the individual bridges found in the file; check first to see whether it is already
# running, otherwise go ahead and call the arguments found in the top of the file to start
# the bridge service running on the server
sub start {
	my @bridges = readFile();
	foreach my $row (0..(@bridges-1)) {
		my @procstatus = "ps -ef|grep $bridges[$row][2]";
		if(@procstatus > 2) { printf "Not starting $bridges[$row][3] - already running\n"; }
		else { 
			printf "Going to start bridge $bridges[$row][3]\n";
			`$bridge->{exec} -g $bridges[$row][0] -m $bridges[$row][1] -u $bridges[$row][2] $bridge->{options} >> $bridge->{logdir}/$bridges[$row][3] &`;
		}
	}

	exit 0;
}

# Loop through the list of bridges in the data file and use that information
# to kill the process. There is no need at all to kill it cleanly since that
# doesn't really exist, so we can just pkill the processes.
sub stop {
	my @bridges = readFile();
	foreach my $row (0..(@bridges-1)) {
		my $procstatus = `ps -ef|grep $bridges[$row][2]`;
		if ($procstatus =~ m/$bridges[$row][2]/) {
			my @getpid = split(/[ ]+/,$procstatus);
			my $cnt = 0;
			$cnt = kill 9,$getpid[1];
			printf "Process $getpid[1] for bridge $bridges[$row][3] killed: $cnt\n";
		}
	}

	exit 0;
}

# Provide some simple user-side documentation for what this script is supposed to do
sub help {
	printf "Welcome to the AccessGrid bridge manager. This is the 'new' way of managing the bridges running 
to convert the multicast streams that RIT produces into unicast in order for external machines without multicast 
to be able to access them.

./server.pl [option]
	help		This prints all the help information (but you already did that, so why does it matter?)
	status		Show the status of all the bridges currently managed by this bridge program
	status [# # #]	List the status only of the bridge(s) specified
	start		Run through the list of supported bridges and start all of them
	stop		This stops *all* of the bridges. We have not built out per-stream functionality for this yet

Example usage:
	./server.pl status hd1 hd2
	./server.pl start
		\n";

	exit 0;
}

if(@ARGV == 0) { printf "Usage: $usage\n"; }
else {
	SWITCH: foreach(@ARGV) {
		/status/i && do { status(@ARGV); };
		/start/i && do { start(@ARGV); };
		/stop/i && do { stop(@ARGV); };
		/help/i && do { help(); };
		printf "Usage: $usage\n";
	}
}
