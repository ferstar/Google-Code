#!/usr/bin/perl
use File::stat;
use Time::localtime;
##########################################################
## Screen capture program
## Revision 0.9.9 - 6-12-12
##
## Usage: ./screenCapt.pl host_file
#Hosts need to run scrot
#Server needs to run imageMagick
my $d=1;
my @nodeList;    #list of nodes
my $script;      #script that will be run
my $nodeFile;    #file containing list of nodes

#Sub to call the nodes and ask for a screenshot



sub getScreen
{
	print "-----------------------  Starting screenshot capture -----------------------\n";
	my $node = $_[0];
	my @output;
	print "Walking $node\n";

	#print "Will run: \"ssh $node \"export DISPLAY=:0\; scrot -d 0 /tmp/$node.png\"\"\n";
	my $erroutput = `ssh $node "/home/user/callScreen.pl"`;

	#if node returns failure
	if ( ${^CHILD_ERROR_NATIVE} != 0 )
	{
		print "SSH returned failure code: ${^CHILD_ERROR_NATIVE}\nMESSAGE $erroutput\n";

		#put black screen with error (assuming node down)
		`convert -size 1280x1024 xc:black /tmp/screencapt/$node.png`;
		`convert $node.png -gravity center -pointsize 75 -fill red -annotate 0x0 \"SSH connect failed\" $node.png`;
	}

	#success!!!!
	else
	{
		print "SSH returned success, transfering image\n";
		print "Will execute: scp -p user\@$node:/tmp/screenshot.png /tmp/screencapt/$node.png\n";
		
		`scp -p user\@$node:/tmp/screenshot.png /tmp/screencapt/$node.png`;
		
		#if scp fails create filler image saying scp failed
		if(${^CHILD_ERROR_NATIVE} != 0 )
		{
			my $x =join(' ',@_);
			print  "SCP failed on node $node Error: ${^CHILD_ERROR_NATIVE}\n";
			`convert -size 1280x1024 xc:black /tmp/screencapt/$node.png`;
			`convert $node.png -gravity center -pointsize 75 -fill red -annotate 0x0 \"SCP connect failed\" $node.png`;
		}
		`chown www-data /tmp/screencapt/$node.png`;

		#push(@output, `ssh $node "rm /tmp/$node.png"`);
		#not necessary - causes more activity when it would just be overwritten
	}
	print "-----------------------  Screenshot capture complete  -----------------------\n\n";
}

#Add datestamp to file
sub dateStamp
{
	my $fileName = $_[0];
	print "Timestapming  $fileName ";
	my $date = ctime( stat("/tmp/screencapt/$fileName")->mtime );
	#print "Date: " . `ls -la /tmp/screencapt/$fileName | awk '{print \$7\" \", \$6}'` . "\n";
	`convert $fileName -gravity SouthEast -pointsize 50 -stroke '#000C' -strokewidth 1 -fill white -annotate +50+20 \"$date\" $fileName`;
	`convert $fileName -gravity SouthWest -pointsize 50 -stroke '#000C' -strokewidth 1 -fill white -annotate +50+20 \"%f\" $fileName`;
	print "-----------------------completed\n";
}

#sub to do the final combination
sub combineAndSize
{
	print "\n-----------------------  Creating filler images   -----------------------\n";
	#gets the number of images mod 4 removes blanks, combined and the totla line from ls -l
	my $blanks=4-(`ls -l /tmp/screencapt/ | grep -v '^total' | grep -v '^combined' | grep -v '^zblank' |  wc -l`%4);
	chomp($blanks);
	#print "DEBUG: blanks is $blanks\n";
	
	if ( $blanks != 0 )#changed from ls -la to ls -l . and .. dirs added -1 for the combined image 
	{
		for ( my $count = 0 ; $count < $blanks ; $count++ )
		{
			print "adding blank image $count OUTPUT:\n";
			print `convert -size 1280x1024 xc:black /tmp/screencapt/zblank-$count.png`;
			print "\n";
			print `convert /tmp/screencapt/zblank-$count.png -gravity center -pointsize 75 -fill blue -annotate 0x0 \"This space left empty\" /tmp/screencapt/zblank-$count.png`;
			print "\n"
		}
	}
	else{print "no blanks needed\n";}
	print "-----------------------  DONE   -----------------------\n\n";
	print "-----------------------  Combining images now   -----------------------\n";
	#Montage the images (in a 4 by X id)
	print `montage  /tmp/screencapt/*.png -background none -bordercolor blue -borderwidth 4 -geometry 1920x1080 -tile 4x /tmp/screencapt/combined.png`;
	print "\nERRORS ${^CHILD_ERROR_NATIVE}\n";
	print "-----------------------  Done   -----------------------\n\n";
	#convert the now giant image to 50% size
	print "-----------------------  Downscaling images now   -----------------------\n";
	print `convert /tmp/screencapt/combined.png -resize 50%  /tmp/screencapt/combined_small.png`;
	print "\nERRORS ${^CHILD_ERROR_NATIVE}\n";
	print "-----------------------  Done   -----------------------\n\n";
	
}

$nodeFile = $ARGV[0];
print "Starting non threaded run @ " . `date` . "\n";
#nodeList(); #list the nodes
#read in list of nodes to walk
print  "-----------------------  Starting node listing  -----------------------\n";
open( NODES, $nodeFile );
while (<NODES>)
{
	chomp $_;
	push( @nodeList, $_ );
	#Add sanity checking here (next revision)
	print "Node $_ added, ";
}
close(NODES);
print "\n-----------------------  Node listing Complete  -----------------------\n\n";

#logic to add temporary directory if it does not exist already
#present only after a reboot
if ( -d '/tmp/screencapt' ) { }
else { `mkdir /tmp/screencapt` }
chdir "/tmp/screencapt";    #change the working direcotry to tmp
print "Cleaning /tmp/screencapt/\n\n";
`rm -f /tmp/screencapt/*`;

#clean the temporary directory - keep the final image clean
#print "DEBUG going to check @nodeList\n";
foreach my $node (@nodeList)
{
	#print "DEBUG checking $node\n";
	chomp($node);
	getScreen($node);
}
#print "DEBUG done checking nodes\n";
my @dirList = <*>;

foreach my $file (@dirList)
{
	chomp($file);
	dateStamp($file);
}

combineAndSize();
print "Completed run @ " . `date` . "\n";
`cp -f /tmp/screencapt/combined_small.png /var/www/screencap/combined_small.png`;
`chown www-data /var/www/screencap/combined_small.png`;
