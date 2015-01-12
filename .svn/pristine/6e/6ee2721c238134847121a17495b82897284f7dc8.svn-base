#!/usr/bin/perl
use Getopt::Long;
use CGI qw(:standard);
use File::stat;
use Time::localtime;

#Todo notes:
#   Clean up the root directory - no need for all the files to sit in there.
#   Clean up this code - still has hanging remanants from original script

#CGI script to allow for instant generation of x desktops
#Contains some leftovers from the original iteration (which will no longer work thanks to key sharing)

my @nodeList; #list of nodes
my $script; #script that will be run
my $nodeFile; #file containing list of nodes

my $display = 0; #Showing display nodes 
my $broadcast = 0; #shoing broadcast nodes
my $master = 0; #this will be the header script always
my $only = 0; #Sets the script to do everything on its own (classic mode)
my $combined = 0; #shows nodes that do both sending and recieving
my $all = 0; #Show EVERY node present
my $force = 0; #Force a re-render (if True)
my $ipadSafe = 0; #(attempt to) Gennerate and image that should fit into iPad's memory
my $modDate = 0; #mod date

my $q = CGI->new;

$display = $q->param('display');
$broadcast = $q->param('broadcast');
$combined = $q->param('combined');
$all = $q->param('all');
$force = $q->param('force');
$only = $q->param('only');
$ipadSafe = $q->param('ipad');


#sub to grab nodes specified
sub nodeList
{
    if(defined $nodeFile)
    {}
    else
    {
        $nodeFile = "/var/www/screencap/allNodes";
    }
    #read in list of nodes to walk
    open(NODES, $nodeFile);
    while(<NODES>)
    {
        chomp $_;
        if(/^\s*$/)
        {
            print "Empty line pulled @ $. - you should remove this, but I will ignore it for now\n";
        }
        else
        {
            push(@nodeList, $_);
        }
    }
    close(NODES);
}

#sub to do the final combination
sub combineAndSize
{
    my $fnames = $_[0];
    my $outputName = $_[1];
    my $displayString = $outputName;
    $displayString =~ tr/a-z/A-Z/;

    print "Creating output for query: $displayString &nbsp; - &nbsp;";
    print "At " . `date`. "<br/>";

    #combine the images
    `montage  $fnames -background black -bordercolor blue -borderwidth 4 -geometry 1920x1080 -tile 4x /var/www/screencap/cgi-imgs/$outputName.png`;

    #convert the now giant image to 50% size
    my $fileName = '/var/www/screencap/cgi-imgs/' . $outputName . '_small.png';
    
    #Downscale the image
    `convert /var/www/screencap/cgi-imgs/$outputName.png -resize 50%  $fileName`;

    `chown www-data /var/www/screencap/cgi-imgs/$outputName.png`;
}

#sub to generate HTML
sub renderHTML
{
    my $type = $_[0];


    #generate HTML code
    print "<html>\n",
          "     <head>\n",
          "         <!-- Refreshes every 5 minutes --> \n",
          "         <meta http-equiv=\"refresh\" content=\"300\">\n",
          "         <title>Grav Locations - " . $type . "s  only</title>\n",
          "         <script type=\"text/javascript\">\n",
          "         <!--\n",
          "             function delayer(){\n",
          "                 window.location=\"https://lovelace.rit.edu/screencap/cgi-bin/screencapt.cgi?" . $type. "=1\"\n",
          "             }\n",
          "          //-->\n",
          "     </script>\n",
          "     </head>\n",
          "     <body>\n";

    #Render remaining information
    if($oldRender == 0)
    {
         print "Seconds since last generation: " . (time - $modDate) . "\n",
               "         <a href=\"/screencap/cgi-imgs/" . $type ."_small.png\"><img width=\"100%\" src=\"/screencap/cgi-imgs/". $type . "_small.png\"/></a>";
    }
    else
    {
        my $renderDate = `ls -la /var/www/screencap/cgi-imgs/broadcast_small.png | awk '{print \$8 \" \", \$6 \" \", \$7}'`;
        print "Image has been rendered within the past five minutes<br/>",
              "Last render time: $renderDate (it is now " . `date +%X` . ")<br/>";

        print "         <a href=\"/screencap/cgi-imgs/" . $type ."_small.png\"><img width=\"100%\" src=\"/screencap/cgi-imgs/". $type . "_small.png\"/></a>",
              "<p>\n",
              "This image was rendered previously to this page refresh to prevent unecessary processor cycles (as noted at the top of this page). If\n",
              "you would like to see it re-rendered, please click <a href=\"https://lovelace.rit.edu/screencap/cgi-bin/screencapt.cgi?" .$type . "=1",
              "&force=1\">here</a>\n",
              "</p>";
    }

    #user requested that it be reloaded
    if($force == 1)
    {
        #force page change after 250 seconds
        print "<body onLoad=\"setTimeout('delayer()', 250000)\">\n";
    }
    print " </body></html>\n";
}
sub getHTMLnodes
{
    my $type = $_[0];
    my $list = "";
    open(NODELIST, "/var/www/screencap/nodeList/". $type . "Nodes");
    while(<NODELIST>)
    {
        if(/^\s*$/) { } #empty Line
        else
        {
            chomp $_;
            $list = $list . "/tmp/screencapt/" . $_ . ".png ";
        }
    }
    close(NODELIST);
    combineAndSize($list, $type);
}
#render a header any way this program runs
print $q->header;

if($display == 1)
{
    my $list = "";
 
    #check to see last render time
      
    $modDate = `stat -c %X /var/www/screencap/cgi-imgs/display_small.png` ;
   
    if((time - $modDate > 600) || $force == 1)
    {
        $oldRender = 0;
        getHTMLnodes("display");
    }
    else
    {
        $oldRender = 1;
    }
    renderHTML("display");
}
if($broadcast == 1)
{
    my $list = "";
 
    #check to see last render time
      
    $modDate = `stat -c %X /var/www/screencap/cgi-imgs/broadcast_small.png` ;
   
    if((time - $modDate > 600) || $force == 1)
    {
        $oldRender = 0;
        getHTMLnodes("broadcast");
    }
    else
    {
        $oldRender = 1;
    }
    renderHTML("broadcast");
}
if($combined == 1)
{
    my $list = "";

    #check to see last render time

    $modDate = `stat -c %X /var/www/screencap/cgi-imgs/combined_small.png` ;

    if((time - $modDate > 600) || $force == 1)
    {  
        $oldRender = 0;
        getHTMLnodes("combined");
    }
    else
    {  
        $oldRender = 1;
    }
    renderHTML("broadcast");
}
my $list = "";

#check to see last render time
#$modDate = `stat -c %X /var/www/screencap/cgi-imgs/" . $name ." _small.png`;
#if((time - $modDate > 600) || $force == 1)
#{
#    $oldRender = 0;
#    getHTMLnodes($name);
#}
#else
#{
#    $oldRender = 1;
#}
#renderHTML($name);

if($ipadSafe == 1)
{   
    $oldRender = 1;
    $modDate = `stat -c %X /var/www/screencap/cgi-imgs/ipad_display.png`;
    if((time - $modDate > 600) || $force == 1)
    {
        $oldRender = 0;
        `convert /var/www/screencap/combined_small.png -resize 50% /var/www/screencap/cgi-imgs/ipad_display.png`;
    }
    print "<html>\n",
              "     <head>\n",
              "         <!-- Refreshes every 5 minutes --> \n",
              "         <meta http-equiv=\"refresh\" content=\"300\">\n",
              "         <title>iPad Friendly View</title>\n",
              "     </head>\n",
              "     <body>\n",
              "         <a href=\"https://lovelace.rit.edu/screencap/cgi-imgs/ipad_display.png\"><img width=\"100%\" src=\"https://lovelace.rit.edu/screencap/cgi-imgs/ipad_display.png\"/></a>";
    if($oldRender == 1)
    {
            print "<p>Image has been rendered in the last five minutes</p>";
    }
    print "     </body>\n";
}
exit;
