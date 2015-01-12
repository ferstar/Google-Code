#!/usr/bin/perl
use File::stat;
use Time::localtime;
use threads;
require threads;
##########################################################
## Screen capture program
## Revision 0.9.9.t - 6-12-12
##
## Usage: ./screenCapt.pl host_file
#Hosts need to run scrot
#Server needs to run imageMagick
my $d=1;
my @nodeList;    #list of nodes
my $script;      #script that will be run
my $nodeFile;    #file containing list of nodes
my @threads;
my @output;
#Sub to call the nodes and ask for a screenshot



sub getScreen
{
	my $ret;#return value of the thread
	my $node = $_[0];
	$ret.= "-----------------------  screenshot of $node -----------------------\n";

	#print "Will run: \"ssh $node \"export DISPLAY=:0\; scrot -d 0 /tmp/$node.png\"\"\n";
	my $erroutput = `ssh $node "/home/user/callScreen.pl"`;

	#if node returns failure
	if ( ${^CHILD_ERROR_NATIVE} != 0 )
	{
		$ret.= "SSH returned failure code: ${^CHILD_ERROR_NATIVE}\nMESSAGE $erroutput\n";

		#put black screen with error (assuming node down)
		$ret.='making ssh errror img '.`convert -size 1280x1024 xc:black /tmp/screencapt/$node.png 2>&1`;
		$ret.="\nlableing ".`convert $node.png -gravity center -pointsize 75 -fill red -annotate 0x0 \"SSH connect failed\" $node.png 2>&1`;
	}

	#success!!!!
	else
	{
		$ret.= "SSH sucess, will execute: scp -p user\@$node:/tmp/screenshot.png /tmp/screencapt/$node.png\n";
		
		$ret.='OUTPUT'.`scp -p user\@$node:/tmp/screenshot.png /tmp/screencapt/$node.png`;
		
		#if scp fails create filler image saying scp failed
		if(${^CHILD_ERROR_NATIVE} != 0 )
		{
			my $x =join(' ',@_);
			$ret.=  "SCP failed on node $node Error: ${^CHILD_ERROR_NATIVE}\n";
			$ret.='making blank img '.`convert -size 1280x1024 xc:black /tmp/screencapt/$node.png 2>&1`;
			chomp $ret;
			$ret.='adding error lable '.`convert $node.png -gravity center -pointsize 75 -fill red -annotate 0x0 \"SCP connect failed\" $node.png 2>&1`;
			chomp $ret;
		}
		$ret.="\nrunning chown".`chown www-data /tmp/screencapt/$node.png 2>&1`;

		#push(@output, `ssh $node "rm /tmp/$node.png"`);
		#not necessary - causes more activity when it would just be overwritten
	}
	$ret.= "\n-----------------------  Screenshot capture complete  -----------------------\n\n";
	return $ret;
}

#Add datestamp to file
sub dateStamp
{
	my $ret;
	my $fileName = $_[0];
	$ret.="Timestapming  $fileName -----------------------\n";
	my $date = ctime( stat("/tmp/screencapt/$fileName")->mtime );
	#print "Date: " . `ls -la /tmp/screencapt/$fileName | awk '{print \$7\" \", \$6}'` . "\n";
	$ret.="datestamping ".`convert $fileName -gravity SouthEast -pointsize 50 -stroke '#000C' -strokewidth 1 -fill white -annotate +50+20 \"$date\" $fileName 2>&1`;
	chomp $ret;
	$ret.="\nadding hostname ".`convert $fileName -gravity SouthWest -pointsize 50 -stroke '#000C' -strokewidth 1 -fill white -annotate +50+20 \"%f\" $fileName 2>&1`;
	chomp $ret;
	$ret.="\n----------------------- completed\n\n";
	return $ret;
}

#sub to do the final combination
sub combineAndSize
{
	print "-----------------------  Creating filler images   -----------------------\n";
	#gets the number of images mod 4 removes blanks, combined and the totla line from ls -l
	my $blanks=(4-(`ls -l /tmp/screencapt/ | grep -v '^total' | grep -v '^combined' | grep -v '^zblank' |  wc -l`%4))%4;
	chomp($blanks);
	#print "DEBUG: blanks is $blanks\n";
	
	if ( $blanks != 0 )#changed from ls -la to ls -l . and .. dirs added -1 for the combined image 
	{
		for ( my $count = 0 ; $count < $blanks ; $count++ )
		{
			print "adding blank image $count \n";
			print "making filler ".`convert -size 1280x1024 xc:black /tmp/screencapt/zblank-$count.png 2>&1`;
			print "lableing ".`convert /tmp/screencapt/zblank-$count.png -gravity center -pointsize 75 -fill blue -annotate 0x0 \"This space left empty\" /tmp/screencapt/zblank-$count.png 2>&1`;
		}
	}
	else{print "no blanks needed\n";}
	print "-----------------------  DONE   -----------------------\n\n";
	print "-----------------------  Combining images now   -----------------------\n";
	#Montage the images (in a 4 by X id)
	#add threading here as well
	print `montage  /tmp/screencapt/*.png -background none -bordercolor blue -borderwidth 4 -geometry 1920x1080 -tile 4x /tmp/screencapt/combined.png`;
	print " ERRORS ${^CHILD_ERROR_NATIVE}\n";
	#wait for threads
	print "-----------------------  Done   -----------------------\n\n";
	#convert the now giant image to 50% size
	print "-----------------------  Downscaling images now   -----------------------\n";
	print `convert /tmp/screencapt/combined.png -resize 50%  /tmp/screencapt/combined_small.png`;
	print " ERRORS ${^CHILD_ERROR_NATIVE}\n";
	print "-----------------------  Done   -----------------------\n\n";
}

$nodeFile = $ARGV[0];
print "Starting threaded run @ " . `date` . "\n";
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
#THREADING TIME based on AGWalker script
print "creating getscreen threads";
foreach my $node (@nodeList)
{
	#print "DEBUG checking $node\n";
	chomp($node);
	
	#start as thread getScreen($node) 
	push(@threads, threads->create('getScreen',$node));
	print "-";
}
print "done\n";
#print "DEBUG done checking nodes\n";

#wait for threads to complete
print "joining threads ";
foreach (@threads)
{
	push(@output,$_->join());
	print "-";
}
print "done\n\n";

print "@output";#prints the output of all threads

my @dirList = <*>;
@threads=();#empty threads arry to take in new threads

print "creating datestamp threads ";
foreach my $file (@dirList)
{	
	chomp($file);
	#start as thread dateStamp($file);
	push(@threads, threads->create('dateStamp',$file));
	print "-";
}
print " done\n";

#wait for threads to complete
print "joining threads ";
foreach (@threads)
{
	push(@output,$_->join());
	print "-";
}
print "done\n\n";

print "@output";#prints the output of all threads

combineAndSize();
print "Completed run @ " . `date` . "\n";
`cp -f /tmp/screencapt/combined_small.png /var/www/screencap/combined_small.png`;
`chown www-data /var/www/screencap/combined_small.png`;
