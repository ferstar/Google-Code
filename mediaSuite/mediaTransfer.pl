#!/usr/bin/perl

use strict;
use warnings;
use Net::SMTP;
use Getopt::Std;
use Cwd 'abs_path';

my %options=();
getopts("f:m:h:M:e:d:", \%options);

my $messageString;
my $extraArgs = "";
my $linkerPath = abs_path('./mediaLinker.pl');
my $file = $options{f};
my $media = $options{m};
my $dayStartHour = $options{h};
my $dayStartMin = $options{M};
#my $to_addr = $options{e};
my $to_addr = 'user@localhost';
my $delayTime = $options{d};

#Perform conversion actions
sub conversion
{
    #Check filetypes using whitelist
    my $extension = filetypeCheck();

    #Work with Zip
    #This implies an image show and will result in an exit after calling it
    if($extension eq 'zip')
    {
        system("logger 'zip file'");
        unZip();
    }
    
    #write cron informations
}
sub filetypeCheck
{
    #Variable to determine fate of file
    #If it is zero at the end of this sub, we feed it to the lions.
    #   (delete and tell the user)
    #Else, pass.
    my $accept = 0;
    my $extension = ($file =~ m/([^.]+)$/)[0];
    #We want to check the filetype to make sure that we want it on our system
    #ppt might be supported soon.
    my @whitelist = ( "mp4", "mp3", "m4a", "mkv", "zip", "png", "jpg"); 
    foreach my $type(@whitelist)
    {
        if($extension eq $type)
        {
            $accept = 1;
            last;
        }
    }
    if($accept == 0)
    {
        #BEGIN THE FEAST!!!!
        unlink($file);
        fail("File Type check", "Invalid file type was sent.");
        die "Invalid filetype\n";
    }
    print "Filetype check passed\n";
    return $extension;
}
sub unZip
{
    #Create a subdirectory for the zip file
    my $basename = substr($file, 0, rindex($file, '.'));
    mkdir($basename);
    #Extract to directory
    system("unzip -jo -d $basename " . $file);
    if ($? != 0)
    {
        fail("Unzip", "System could not find file specified (" . $? .")");
    }
    
    #next we need to rename "Slide#.png" to "Slide0#.png"
    chdir($basename);
    my @fileList = glob('*.*');
    
    foreach my $file(@fileList)
    {
        if($file =~ m/[sS]lide[\d]\..{3,4}/)
        {
            my $slideNumber = substr($file, 5, 1);
            my $extension = substr($file, (rindex($file,'.')+1));
            system("mv $file Slide0$slideNumber.$extension");
        }
    }
    chdir("../../");
    
    #We want to play the folder
    $file = $basename;
}     
sub writeCrontab
{
    my $currentCrontab = `crontab -l`;
    my $username = `whoami`; 
    my @crontab = split("\n", $currentCrontab);
    my $playerLocation = -1;

    for(my $counter = 0; $counter < @crontab; $counter++)
    {
        if(index($crontab[$counter], "mediaLinker.pl") != -1)
        {
            $playerLocation = $counter;
        }
    }
    if($media == 1)
    {
        $crontab[$playerLocation] = "$dayStartMin $dayStartHour   *   *   1-5  $linkerPath $extraArgs -AVUf $file";
        $messageString = "New cronjob installed: \n\t $crontab[$playerLocation]\n";
    }
    elsif($media == 0)
    {
        ## Media is PPT and should be converted.... added to startup somehow?
        open(TMP, ">/tmp/at_cmd");
        print TMP "$linkerPath $extraArgs -d $file -i -T $delayTime\n";
        close TMP;
        system("at $dayStartHour$dayStartMin today -f /tmp/at_cmd");
        unlink("/tmp/at_cmd");
        exit(0);
    }
    elsif($media == 2)
    {
        open(TMP, "> /tmp/at_cmd");
        print TMP "$linkerPath $extraArgs -F $file -i -T $delayTime\n";
        close TMP;
        system("cat /tmp/at_cmd");
        system("at $dayStartHour$dayStartMin today -f /tmp/at_cmd");
        unlink("/tmp/at_cmd");
        exit(0);
    }

    #backup crontab
    system("crontab -l > ./backupCrontab");
    
    #write new crontab
    open(CRON, '| crontab -') or fail("Crontab", $!);
    foreach my $cronjob(@crontab)
    {
        print CRON $cronjob . "\n";
    }
    close(CRON);
    print `crontab -l`;
}
sub fail
{
    my $location = $_[0];
    my $reasonCode = $_[1];
    $messageString = "Execution of transfer program failed:\n" .
                        "\tAt: $location\n".
                        "\tReason: $reasonCode\n".
                        "Please fix the problems and resubmit the file\n";
    sendMessage($messageString, "FAILURE");
    die("Failure in $location because $reasonCode");
}
sub sendMessage
{
    my $messageString = $_[0];
    my $state;
    my $hostname = `hostname`;

    #create state transistion
    if(defined $_[1])
    {
        $state = $_[1] . ": ";
    }
    else
    {
        $state = "";
    }

    #prepare and send email
    chomp($hostname);
    my $sender = "MediaPlayer@" . $hostname;
    my $smtp = Net::SMTP->new('mail.rit.edu');
    $smtp->mail($sender);
    $smtp->recipient($to_addr);
    $smtp->data;
    $smtp->datasend("From: $sender\n");
    $smtp->datasend("To: $to_addr\n");
    $smtp->datasend("Subject: " . $state . "MediaPlayer on $hostname\n");
    $smtp->datasend("\n");
    $smtp->datasend($messageString);
    $smtp->dataend;
    $smtp->quit;
}
conversion();
writeCrontab();
sendMessage($messageString, "SUCCESS");
