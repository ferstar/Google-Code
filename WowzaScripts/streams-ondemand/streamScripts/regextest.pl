#!/usr/bin/perl -w
use strict;

sub checkip($)
{
	chomp $_[0];
	print $_[0]."\n";
if ($_[0] =~ m/^
	#match ip	
	(
		(25{1}[0-5] #match 250-255
		|2[0-4]\d	#match 200-249
		|[0-1]?\d\d #match 099-199
		| 0?\d?\d)	#match 0-99	
		\.			#match a . 
	){3}			#repeat 3 times
	(
		25{1}[0-5] #match 250-255
		|2[0-4]\d	#match 200-249
		|[0-1]?\d\d #match 099-199
		| 0?\d?\d		#match 0-99
	)				#once more without the .
	\/
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
	$/x)
	{
		print "good\n";
		return 1;
	}
	die("failed $_[0]\n");
	return 0;
}
chomp $ARGV[0];
if(checkip($ARGV[0])){print"good\n"};
__END__
my $ret;
for(my $a=0; $a<=255; $a++)
{
	for(my $b=0; $b<=255; $b++)
	{
		for(my $c=0; $c<=255; $c++)
		{
			for(my $d=0; $d<=255; $d++)
			{
				&checkip("$a.$b.$c.$d");
				
			}
		}
	}
}