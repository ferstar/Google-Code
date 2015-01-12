#!/usr/bin/perl -w

use strict;

my @ostrich=qw(00 01 02 03 04 05 06 07 08 09 10 11 12 13);
my @epenguin=qw(00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19);
my @errors;
sub p
{
	print `ping -c 2 $_[0].rit.edu`;
	if ( ${^CHILD_ERROR_NATIVE} != 0 )
	{
		push(@errors,"ERROR ${^CHILD_ERROR_NATIVE}\n");
	}
}


foreach (@ostrich){p("ostrich-$_");}

foreach (@epenguin){p("epenguin-$_");}

print "ERRORS------\n\n";
print  split(/\n/,@errors);
