#!/bin/bash
#
# Script for taking a screenshot of an H.264 video over multicast RTP.
# @author Andrew Ford
# Usage: ./gst-rtp-h264-view.sh [source ip] [source port] [path prefix] [file prefix]

# Multicast source IP/port
DEST=$1
PORT=$2
RTCPPORT=$(($2+1))

PATHPREFIX=$3
FILEPREFIX=$4

OLDFILENAME="$PATHPREFIX$FILEPREFIX$DEST.$PORT-`date +%F-\(%u\)-%H-%M-%S`"

#PATH="$PATHPREFIX$DEST.$PORT-`date +%F-\(%u\)`"
#FILENAME="$FILEPREFIX$DEST.$PORT-`date +%F-\(%u\)-%H-%M-%S`"

#FULLPATH="$PATH/$FILENAME"

# this adjusts the latency in the receiver
LATENCY=0

# Proper video caps for H.264
VIDEO_CAPS="application/x-rtp,media=(string)video,clock-rate=(int)90000,encoding-name=(string)H264"

gst-launch-0.10 -v gstrtpbin name=rtpbin latency=$LATENCY              \
     udpsrc caps=$VIDEO_CAPS multicast-group=$DEST port=$PORT !        \
       rtpbin.recv_rtp_sink_0                                          \
       rtpbin. ! rtph264depay ! ffdec_h264 ! videorate !               \
       "video/x-raw-yuv, framerate=(fraction)1/1" ! ffmpegcolorspace ! \
       pngenc snapshot=false ! multifilesink location=$OLDFILENAME.png

