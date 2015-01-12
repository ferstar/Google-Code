#!/usr/bin/perl -w
use strict;

#takes in a file of hosts or a list of hosts and pushes a file down to all of them  
#should be run on lovelace

my $file;
my $loc;
my $error;

if (@ARGV<3)
{
	die "USAGE ./filePushWalker.pl fileToPush LocationToPushTo HostsList\n";
}

$file=shift @ARGV;
$loc=shift @ARGV;

foreach (@ARGV)
{
	print "------------------- $_ -------------------\n\n";
	print "running scp $file $_:$loc\n";
	print `scp $file $_:$loc`;
	if (${^CHILD_ERROR_NATIVE} != 0 )
	{
		print STDERR "$_ ERROR ${^CHILD_ERROR_NATIVE}";
		$error.="$_ ERROR ${^CHILD_ERROR_NATIVE}\n";
	}
	print "\n------------------- DONE -------------------\n\n";
}
if (! $error){	$error="NONE!";}
print "\n EXECUTION COMPLETE \n errors: $error\n";




