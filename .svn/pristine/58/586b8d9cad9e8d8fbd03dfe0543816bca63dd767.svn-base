#!/usr/bin/perl

use Cwd 'abs_path';
use File::Basename;
use File::Spec::Functions qw(rel2abs);
use Sys::Load;

#Modules to enable program to determine where it lives
use FindBin '$RealBin';

use Dancer;
use Dancer::Request;
use Dancer::Request::Upload;
use Template;

set 'session'  => 'Simple';
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;

my $scheduleFile =  File::Spec->rel2abs($RealBin . '/../../schedule.dat');
my $mediaStore = File::Spec->rel2abs($RealBin . '/../../mediaStore/');
print "Using Schedule File: $scheduleFile\n";
print "Storing files in: $mediaStore\n";
prefix undef;

#Sub to clean user input
sub untaint
{
    my $startTimeHour = $_[0];
    my $startTimeMin = $_[1];
    my $delayTimeMin = $_[2];

    my $err = "";
    
    ($startTimeHour, $err) = clStartHour($startTimeHour, $err);
    ($startTimeMin, $err) = clStartMin($startTimeMin, $err);
    ($delayTimeMin, $err) = clDelayMin($delayTimeMin, $err);

    if($err eq "") { $err = "None."; }
    return ($err, $startTimeHour, $startTimeMin, $delayTimeMin);
}
sub clStartHour
{
    my $startTimeHour = $_[0];
    my $err = $_[1];
    
    if($startTimeHour =~ /^([0-9]{1,2})$/ && $startTimeHour < 25) 
    {
        $startTimeHour = $1;
        if(length($startTimeHour) == 1)
        {
            $startTimeHour = '0' . $startTimeHour;
        }
    }
    else {$err = $err .  "Start hour contains invalid characters or is invalid time (>24) ";}
    
    return ($startTimeHour, $err);
}
sub clStartMin
{
    my $startTimeMin = $_[0];
    my $err = $_[1];
    
    if($startTimeMin =~ /^([0-9]{1,2})$/ && $startTimeMin < 61) 
    {   
        $startTimeMin = $1;
        if(length($startTimeMin) == 1)
        {
            $startTimeMin = '0' . $startTimeMin;
        }
    }
    else {$err = $err . "Start minute contains invalid characters or is invalid time (>60) ";}
    return ($startTimeMin, $err);
}
sub clDelayMin
{
    my $delayTimeMin = $_[0];
    my $err = $_[1];
    
    if($delayTimeMin =~ /^([0-9]{1,2})$/ && $delayTimeMin < 61 ) 
    {
        $delayTimeMin = $1;
        if(length($delayTimeMin) == 1)
        {
            $delayTimeMin = '0' . $delayTimeMin;
        }
    }
    else {$err = $err . "Delay minute contains invalid characters or is invalid time (>60) ";}
    
    return($delayTimeMin, $err);
}
sub cleanString
{
    $_[0] =~ s/[\s]+/_/g;           #Remove all whitespace
    $_[0] =~ s/[^a-zA-Z0-9.]+//g;    #*should* remove anything that is not alphanumeric
    $_[0] =~ s/[\.]{2,}//g;            #multiple periods
    return $_[0];
}
#Sub to check incoming file for threats
#Method will call die if file is contaminated
#Tested with eicar.com (11/08/2011) to confirm it works
#ARGUEMENTS:
#   $_[0] - file to check
sub clamScan
{
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #End check early - testing mode.
    #return("ClamAV states file is clean\n");
    #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    checkDependency("clamscan");
    debug "Clamscan!";
    my $scan = `clamscan --no-summary $_[0] 2>/dev/null`;
    my $checkString = "$_[0]: OK";
    debug $scan;
    if($scan !~ m/($checkString)/)
    {
        #get the file off of the system
        unlink($_[0]);
        #tell the user that they need to watch their uploads
        return halt ("VIRUS DETECTED IN UPLOAD! \n" .
                            "Please ensure your files are clean!!! \n" .
                            "<strong>File " . $_[0] . " erased due to virus infection</strong>\n");
    }
    else
    {
        return ("ClamAV states file is clean\n");
    }
}
#Sub to check to see if a required program is installed
#ARGUEMENTS:
#   $_[0] - program name
#RETURNS:
#   0 if program is installed
#CALLS:
#   die if the program is not found
sub checkDependency
{
    my $programCheck = $_[0];
    my $result = `which $programCheck`;
    chomp($result);
    if(length($result) < 2)
    {
        die "Required program: $programCheck not found. Please install and re-run\n";
    }
    return $?;
}
# Sub to append information to a schedule file for later dumping
#File format:
#Type   Start Time  Days(0000000)  File    Command
sub doSchedule
{
    debug "scheduling!";
    my @schedule;
    my $content = 0;
    my $days = '0111110';
    my $insert = 0; #This bit will change to 1 when the item has been added
    if(!-e '../../schedule.dat')
    {
        system('touch ../../schedule.dat');
    }

    #Get last schedule
    open(SCH, '<../../schedule.dat');
    while(<SCH>)
    {
        if(substr($_, 0,1) ne '#' && $_ !~ /^$/)
        {
            chomp($_);
            push(@schedule, $_);
        }
    }
    close(SCH);
    #Write new schedule
    open(SCH,'>../../schedule.dat');
    print SCH "#DO NOT MODIFY THIS FILE.\n";
    print SCH "#Type\tstartTime\tFile\tCommand\n";
    foreach my $item (@schedule)
    {
        my @parts = split(/\t/, $item);
        #Check filename
        if($parts[3] eq $_[2])
        {
            #check start time
            if($parts[2] eq $_[1])
            {
                #2 out of 4 occurences is enough to justify repeat (and thus replace)
                $item = "$_[0]\t$_[1]\t$days\t$_[2]\t$_[3]\n";
                $insert = 1;
                print SCH $item;
            }
        }
        else
        {
            print SCH $item . "\n";
        }
        debug $item;
    }
    if($insert != 1)
    {
        print SCH "$_[0]\t$_[1]\t$days\t$_[2]\t$_[3]\n";
    }
    close(SCH);
}
#Create a shell script to run/cronjob
sub createParseCommands
{
    my $file = $_[0];
    my $startTimeHour = $_[1];
    my $startTimeMin = $_[2];
    my $delayTime = $_[3];
    my $media = $_[4];
    my $date = `date +%m%d`;
    chomp($date);

    clamScan($file->tempname);
    #Build a shell script that will cause every command to be executed sequentially.
    #Notify console of status
    debug "Beginning sequential file build of " . $file->filename;
    
    #move file to user directory
    my $destinationFile = $mediaStore . '/' . $file->filename;
    $destinationFile =~ s/[\s']/_/g;
    debug "Destination file: $destinationFile";
    $file->copy_to($destinationFile);

    #Create file
    my $filename = $mediaStore . '/' . substr($file->filename, 0, rindex($file->filename, '.')) . '.play';
    $filename =~ s/\s/_/g;
    debug "Playfile name: $filename";
    system("touch $filename");
    open(SCRIPT, ">$filename") or die $!;
    print SCRIPT '#!/bin/bash' . "\n";
    
    #TODO: Figure out the handoff
    my $cmd = "~/mediaSuite/mediaTransfer.pl -f $destinationFile -m $media -h $startTimeHour -M $startTimeMin ";
    
    if ($delayTime ne "00")
    {
    	$cmd = $cmd . "-d $delayTime\n";
    }
    else {$cmd = $cmd . "\n";}
    print SCRIPT $cmd;
    debug $cmd;
    print SCRIPT 'rm "$0"' . "\n";
    close(SCRIPT);
    debug "Script for " . $file->filename . " has been written";
    doSchedule($media, "$startTimeHour:$startTimeMin",  $destinationFile, $cmd);
}
get '/' =>  sub {
	redirect '/schedule';
};
#Sub to get system info (Hidden from user by default)
get '/sysinfo' => sub {
    #Get system uptime
    my $uptime = Sys::Load::uptime();
    my $hourUptime = int($uptime/3600);
    my $minuteUptime = int(($uptime - $hourUptime*3600)/60);
    $uptime = "$hourUptime hours $minuteUptime  minutes"; 
    my $recitalTime = `ps -o etime $$ | sed 1d`;
    my @avgs = Sys::Load::getload();
    my $load = "$avgs[0] $avgs[1] $avgs[2]";
    my $hostname = `hostname`;
    template 'sysinfo.tt', {
        'uptime' =>$uptime,
        'hostname' => $hostname,
        'load' => $load,
        'dance' => $recitalTime,
    };
};

#sub to display licensing information
get '/license' => sub {
    template 'license.tt', {};
};
#Sub to shutdown the server
any ['get', 'post'] => '/exit/0x0' => sub {
    debug "Exiting on request of " . request->remote_address . "\n";
    debug "You Monster.\n";
    exit(0);
};
#sub to restart the server
any ['get', 'post'] => '/exit/0x2' => sub {
    halt "Route execution disabled - causes CSS problems. shoerner 2/9/12";
    debug "Restarting software now\n";
    exec(abs_path($0));
};
any ['get', 'post'] => '/exit/0x4' => sub {
    debug "Web request: Killing all child processes";
    system("pkill chrome*");
    system("pkill feh");
    system("pkill mplayer");
    redirect '/sysinfo';
};

#Userform for file submissions
any ['get', 'post'] => '/upload' => sub {
    my $err = "None.";
    if(request->method() eq "POST")
    {
        my $file = request->upload('uploadFile');
        my $mediaType = param('media');
        my $startTimeHour = param('startHour');
        my $startTimeMin = param('startMinute');
        my $delayTimeMin = param('delayMinute');
        my $err;
        if($mediaType == 0)
        {
            ($err, $startTimeHour, $startTimeMin, $delayTimeMin) = untaint($startTimeHour, $startTimeMin, $delayTimeMin);
            if ($err eq "None.")
            {
                debug "PPT Submission: Start Time: " . $startTimeHour . ':' . $startTimeMin . "\tDelay: $delayTimeMin\n";
                $err = "Successful Upload.";
                createParseCommands($file, $startTimeHour, $startTimeMin, $delayTimeMin, 0);
            }
        }
        elsif($mediaType == 1)
        {
            ($err, $startTimeHour, $startTimeMin, my $junk) = untaint($startTimeHour, $startTimeMin, "00");
            debug "Video submission: Start Time: " . $startTimeHour . ':' . $startTimeMin . "\n";
            $err = "Successful Upload.";
            createParseCommands($file, $startTimeHour, $startTimeMin, "00", 1);
        }
        elsif($mediaType == 2)
        {
            my @time = localtime(time);
            ($delayTimeMin,$err) = clDelayMin($delayTimeMin, '');
            debug "Advertisement submission. Starting in $delayTimeMin minutes\n";
            createParseCommands($file, $time[2], ($time[1]+1), $delayTimeMin, 2);
        }
    }
    
    #Undef $err to prevent display to user and redirect to schedule
    if($err eq 'None.')
    {
        undef $err;
        if(request->method() eq "POST"){redirect '/schedule';}
    }
    else {$err = "<strong>Message: </strong> $err";}

	template 'upload.tt', {
		'err' =>$err,
	};
};
any ['get', 'post'] => '/queue' => sub {
    my $output = "";
    my $table = "";
    if(request->method() eq "POST")
    {
        if(params->{'type'} eq 'add')
        {
            my $mod = cleanString(params->{'new_qname'});
            system("mkdir $mediaStore/queue_$mod");
        }
        if(params->{'type'} eq 'del')
        {
            my $mod = cleanString(params->{'delQueue'});
            system("rm -rf $mediaStore/queue_$mod");
            debug "removing queue $mod";
        }
    }
    my @queueList = split(/\n/, `find $mediaStore -name 'queue_*' -type d`);
    foreach my $queue (@queueList)
    {
        $queue = substr($queue, rindex($queue, '/'));
        $queue =~ s/queue_//g;
        $queue =~ s/\/+//g;
    }
    @queueList = sort(@queueList);
    foreach my $queue (@queueList)
    {
        $output = $output .
            "<option value=\"$queue\">$queue</option>\n";
        $table = $table .
            "<div class=\"div-table-row\"> <div class=\"div-table-col\"> <a href=\"/queue/$queue\">$queue</a></div></div>\n";
    }
    template 'queue.tt', {
	'queueList' => $output,
        'table'     => $table,
    };
};

#######
# Sub used to get queued media
#######
get '/queue/:queue' => sub {
    my $files = "";
    my $count = 0;
    my $queue = params->{'queue'};
    if($queue !~ m/[a-zA-Z0-9_.]*/g) { debug "Invalid string recieved from idiot in queue view. String: '$queue'";}
    $queue =~ s/[^a-zA-Z0-9_.]*//g;
    $queue =~ s/\s*//g;
    my $queryQueue = "$mediaStore/queue_$queue";
    my @queueList = split(/\n/, `find $queryQueue -type f`);
    if (@queueList < 1)
    {
        $files = "<strong style=\"color:red;font-size:15pt;\">No files found</strong></style>";
    }
    else
    {
        foreach my $mediaFile(@queueList)
        {
            $mediaFile = substr($mediaFile, rindex($mediaFile, '/'));
            $mediaFile =~ s/queue_//g;
            $mediaFile =~ s/\/+//g;
        }
        @queueList = sort(@queueList);
    }
    foreach my $queue (@queueList)
    {
        $files = $files .
            "<div class=\"div-table-row\"> <div class=\"div-table-col\"> <a href=\"/file/$queue\">$queue</a></div></div>\n";
    }
    template 'queueMgr.tt', {
        'table'     => $files,
        'queue'     => $queue,
    };
};
###########
# Sub used to return schedule items
###########
any ['get'] => '/schedule' => sub {
    my $files = "";
    my $count = 0;
    open SCH, "<$scheduleFile" or die "Error reading: $!";
    while(<SCH>)
    {
        if(substr($_,0,1) ne '#' && $_ !~ /^$/)
        {
            my @item = split(/\t/,$_);
            my $fname = fileparse($item[3]);
            $files = $files . 
                "<tr> " . 
                "<td><span style=\"text-align:center\"><a href=\"/delete?file=$fname\"><image width=\"30\" style=\"border-style:none;\" " .
                    "height=\"20\" src=\"images/delete.png\" alt=\"Delete Icon\"></a></span></td>" .
                "<td>$item[1]</td>" .
                "<td>$fname</td>" .
                "</tr>";
        }
        $count++;
    }
    close SCH;
    template 'schedule.tt', {
        'files' => $files,
    };
};
get '/file/:file' => sub{
    my $file = cleanString(params->{'file'});
    
};
get '/delete' => sub {
    
    #!!! Fixed possible exploitation mechanism by cleaning string first
    #TODO: Check to make sure that the file actually exists
    my $deleteFile = cleanString(params->{'file'});

    ##First, kill accessing procs
    #Absolutely disgusting way to do it. But it gets the job done
    system("pkill mplayer");
    system("pkill feh");

    ##Now, delete the file
    if (-e "$mediaStore/$deleteFile")
    {
        system("rm -f $mediaStore/$deleteFile");
    }
    else
    {
        debug "File deletion requested of a file that does not exist. Halting route. Filename: $deleteFile";
        halt "File deletion requested of a file that does not exist. Execution halted.";
    }
    
    ## Open schedule file for read
    open SCH, "<$scheduleFile";
    my @schedule = <SCH>;
    close SCH;
    
    ## Scan cron to remove file
    system("crontab -l | sed '/$deleteFile/d' > crontab");
    
    ## Clean schedule file
    my $out = `grep -v $deleteFile $scheduleFile`;
    open(SCH_OUT, ">", $scheduleFile);
    print SCH_OUT "$out";
    close SCH_OUT;
    redirect '/schedule';
};
#user login
any ['get', 'post'] => '/login' => sub {
   my $err;

   if ( request->method() eq "POST" ) {
     # process form input
     if ( params->{'username'} ne setting('username') ) {
       $err = "Invalid username";
     }
     elsif ( params->{'password'} ne setting('password') ) {
       $err = "Invalid password";
     }
     else 
     {
       session 'logged_in' => true;
       set_flash('You are logged in.');
       redirect '/upload';
     }
  }

  # display login form
  template 'login.tt', { 
    'err' => $err,
  };
};

#(Should) destroy user session
get '/logoff' => sub{
    session->destroy;
    return "Session destroyed.";
};
start;
