#!/usr/bin/bash
#Script could be potentially dangerous! make sure you know what
#gstreamer operations are running on each system before running 
#this script, you could be killing something that you dont want 
#to (such as the capture of of a timelapse or streammon)

#Go through every line of the transcoders file, and kill gstreamer
while read line
do
    transcoder=$line

    echo killing process on transcoder $transcoder
    ssh -n root@$transcoder pkill -9 gst-launch-0.10

done < transcoders

