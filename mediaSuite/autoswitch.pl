#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

$ENV{DISPLAY} = ":0";

my %options=();
getopts("ha:g:t:", \%options);

my $idQuery;
my $widthQuery;
my $heightQuery;
my $flip = 1;

sub help
{
    print "Usage: ./autoswitch.pl -a [application name] -g [time to run grav] -t [time to run other app]\n";
    print "\t-a\tOther application that should be switched to\n";
    print "\t-g\tTime that Grav will be running in the foreground\n";
    print "\t-h\tPrint this help\n";
    print "\t-t\tTime that alternate app will be running in the foreground\n";
}
sub grav
{
    $idQuery = 'wmctrl -l | grep grav | awk \'{ if ( $4 ~/^grav$/ && !($5 ~ /menu/)) print $1 }\'';
    $widthQuery = 'wmctrl -d | awk \'NR==1{print $9}\'| awk -F\'x\' \'{print $1}\'';
    $heightQuery = 'wmctrl -d | awk \'NR==1{print $9}\' | awk -F\'x\' \'{print $2}\'';
    switch();
}
sub otherApp
{
    $idQuery = 'wmctrl -l | awk \'{ if ( $4 ~/^' . $options{a} . '$/) print $1 }\'';
    $widthQuery = 'wmctrl -d | awk \'NR==1{print $9}\'| awk -F\'x\' \'{print $1}\'';
    $heightQuery = 'wmctrl -d | awk \'NR==1{print $9}\' | awk -F\'x\' \'{print $2}\'';
    switch();
}
sub switch
{   
    my $windowID = `$idQuery`;
    my $width = `$widthQuery`;
    my $height = `$heightQuery`;
    
    chomp($windowID);
    chomp($width);
    chomp($height);
    
    #Switch to desktop containing app, raise and give it focus
    system("wmctrl -i -a $windowID");
}

#check arguements
if((!defined($options{a}) || !defined($options{g}) || !defined($options{t})) || $options{h})
{
    help();
    exit(0);
}

#do Program things.
while(1)
{
    if($flip == 0)
    {
        grav();
        $flip = 1;
        sleep($options{g} * 60);
    }
    else
    {
        otherApp();
        $flip = 0;
        sleep($options{t} * 60);
    }
}
