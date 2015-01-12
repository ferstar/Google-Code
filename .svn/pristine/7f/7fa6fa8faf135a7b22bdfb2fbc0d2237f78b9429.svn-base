#!/bin/bash
#
# Call the gst screenshot script on the IHST stream & kill after 10 seconds.
# Note that the capture for this stream now runs on thrasher.
#
# Author: Andrew Ford

/home/user/gst-rtp-h264-screenshot-new.sh 233.17.33.206 50004 /mnt/bluearc-7k/IHST-timelapse-2-daily IHST2 &

PID=`echo $!`
sleep 10
pkill -P $PID

