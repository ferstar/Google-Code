#!/bin/bash
#
# Call the gst screenshot script on the IHST stream & kill after 15 seconds.
# Example for stream2.
# Note the gst script is also in the gst dir in SVN (good idea to copy it to
# somewhere else to prevent SVN changes from affecting production)
# Typically this will be called every minute, by root (depending on perms for
# file dest - 3rd arg in gst script) via crontab.
#
# Author: Andrew Ford

echo "---------------------"
echo "Running gst script... `date`"

/home/user/gst-rtp-h264-screenshot-new.sh 233.17.33.206 50004 /mnt/bluearc-7k/IHST-timelapse-2-example IHST2 &

PID=`echo $!`

echo "Sleeping..."
sleep 15

echo "Killing gst script..."
pkill -P $PID
echo "Done!"
echo "---------------------"
echo

