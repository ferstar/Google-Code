#!/usr/bin/perl

use warnings;

my @nodeList; #list of nodes
my $script; #script that will be run
my $nodeFile; #file containing list of nodes

#sub to grab nodes specified
sub nodeList
{
    #read in list of nodes to walk
    print "-----------------------  Starting node listing  -----------------------\n";
    open(NODES, $nodeFile);
    while(<NODES>)
    {
        chomp $_;
        push(@nodeList, $_);
        print "Node $_ added\n";
    }
    close(NODES);
    print "-----------------------  Node listing Complete  -----------------------\n\n\n";
}

#Sub to call the nodes and ask for a screenshot
sub getScreen
{
    print "-----------------------  Starting screenshot capture -----------------------\n";
    my $node = $_[0];
    my @output;
    print "Walking $node\n";
    #print "Will run: \"ssh $node \"export DISPLAY=:0\; scrot -d 0 /tmp/$node.png\"\"\n";
    `ssh $node "/home/user/callScreen.pl"`;
    if(${^CHILD_ERROR_NATIVE} != 0)
    {
        print "SSH returned failure code: ${^CHILD_ERROR_NATIVE}\n";
        #put black screen with error (assuming node down)
        `convert -size 1280x1024 xc:black /tmp/screencapt/$node.png`;
        `convert $node.png -gravity center -pointsize 75 -fill red -annotate 0x0 \"SSH connect failed\" $node.png`;
    }
    else
    {
        print "SSH returned success, transfering image\n";
        print "Will execute: scp -p user\@$node:/tmp/screenshot.png /tmp/screencapt/$node.png\n";
        `scp -p user\@$node:/tmp/screenshot.png /tmp/screencapt/$node.png`;
        #push(@output, `ssh $node "rm /tmp/$node.png"`);
        #not necessary - causes more activity when it would just be overwritten
    }

    print "-----------------------  Screenshot capture complete  -----------------------\n\n";
}

#Add datestamp to file
sub dateStamp
{
    my $fileName = $_[0];
    print "-----------------------       Timestapming  $fileName      -----------------------\n";
    my $date = `ls -la $fileName | awk '{print \$7\" \", \$6}'`;
    `convert $fileName -gravity SouthEast -pointsize 50 -stroke '#000C' -strokewidth 1 -fill white -annotate +50+20 \"$date\" $fileName`;
    `convert $fileName -gravity SouthWest -pointsize 50 -stroke '#000C' -strokewidth 1 -fill white -annotate +50+20 \"%f\" $fileName`;
    print "-----------------------  Timestapming  $fileName completed -----------------------\n\n";
}

#sub to do the final combination
sub combineAndSize
{
    print "-----------------------  Combining images now   -----------------------\n";
    #my $numberFiles = `ls -la /tmp/screencapt/ | grep \".png\" | wc -l`;
    #while($numberFiles % 4 != 0)
    #{
    #    `convert -size 1280x1024 xc:white /tmp/screencapt/$numberFiles.png`;
    #    `convert $numberFiles.png -gravity south -pointsize 20 -fill blue -annotate 0x0 \"Filler\" $numberFiles.png`;
    #    $numberFiles = `ls -la /tmp/screencapt/ | grep \".png\" | wc -l`;
    #}
    #Montage the images (in a 4 by X id)
    `montage  *.png -background black -monitor -frame 1x -geometry 1920x1080 -tile 4x /tmp/screencapt/combined.png`;
    #convert the now giant image to 50% size
    print "-----------------------  Downscaling images now   -----------------------\n";
    `convert /tmp/screencapt/combined.png -monitor -resize 50%  /tmp/screencapt/combined_small.png`;
}

$nodeFile = $ARGV[0];

#program will call itself back  to repeat every five minutes
while(1==1)
{
    nodeList(); #list the nodes
    chdir "/tmp/screencapt"; #change the working direcotry to tmp
    print "Cleaning /tmp/screencapt/\n"; 
    `rm -f /tmp/screencapt/*`; #clean the temporary directory - keep the final image clean
    foreach my $node(@nodeList)
    {
        chomp($node);
        getScreen($node);
    }
    my @dirList = `ls -la /tmp/screencapt/ | grep \^- | awk '{print \$8}'`;
    foreach my $file (@dirList)
    {
        chomp($file);
        dateStamp($file);
    }
    combineAndSize();
    print "Completed run @ ", `date`, "\n";
    #`eog -f /tmp/screencapt/combined_small.png`;
    #commented to be run on lovelace
    
    `cp -f /tmp/screencapt/combined_small.png /var/www/screencap/combined_small.png`;
    `chown www-data /var/www/screencap/combined_small.png`;

    sleep(300); #sleep for five minutes
}
