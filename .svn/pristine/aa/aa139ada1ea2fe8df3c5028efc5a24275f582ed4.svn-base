#!/usr/bin/perl
use strict;
use warnings;

my @output;
my @currentTemp;
my $highTemp;
my $criticalTemp;

unless(`which sensors`)
{
	print "lm-sensors not installed\n";
	exit 3; #program is not installed
}

@output = `sensors |grep "Core "`;

if(@output < 1)
{
	print "No CPU sensor found on this device - Suggest removal of this check\n";
	exit 3; #box does not have sensors - thus, status unknown
}
if($output[0] eq 'No sensors found!')
{
	print "Program lm-sensors installed, no sensors found. Run sudo sensors-detect and load the kernel modules\n";
	exit 3; #box (might) have sensors, but it cannot open them for reading
} 

foreach my $line (@output)
{
	chomp($line);

        my @core = split(/ /, $line);
	
	#Temperature of cores
	$core[7] = substr $core[7], 1;
	$core[7] = substr $core[7], 0, (length($core[7])-3);
	push(@currentTemp, $core[7]);

	#High temp (assume the same for all cores)
	$core[11] = substr $core[11], 1;
	$core[11] = substr $core[11], 0, (length($core[11])-4);
	$highTemp = $core[11];

	#Critical temperature (Assume same for all cores)
	$core[14] = substr $core[14], 1;
	$core[14] = substr $core[14], 0, (length($core[14])-4);
	$criticalTemp = $core[14];
}
my $avgTemp;
foreach my $core (@currentTemp)
{
	$avgTemp += $core;
}
$avgTemp = $avgTemp/@currentTemp;

print "Average temperature: $avgTemp; System 'high' temperature: $highTemp; System 'crit' temperature: $criticalTemp; Spread out over " . @currentTemp . " cores\n";

if($avgTemp < $highTemp)
{
	exit 0; #temperature is normal/low
}
elsif($avgTemp >= $highTemp) 
{
	if($avgTemp >= $criticalTemp)
	{
		exit 2; #Temperature is in the critical range
	}
	else
	{
		exit 1; #Gettin a lil warm in here isin't it?
	}
}
