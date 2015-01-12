#!/bin/bash
#
# Script for receiving and displaying raw video over RTP.
# @author Andrew Ford
# Usage: ./gst-client-raw-rtp.sh [width] [height] [source ip] [source port]

# Multicast source IP/port
DEST=$3
PORT=$4
RTCPPORT=$(($4+1))

WIDTH=$1
HEIGHT=$2

#note the sampling may need to be changed based on source
#also the width/height have to be string for some reason, doesn't work with int
CAPS="application/x-rtp,media=(string)video,clock-rate=(int)90000,sampling=(string)YCbCr-4:2:0,width=(string)$WIDTH,height=(string)$HEIGHT,framerate=(fraction)30/1"

VCAPS1="video/x-raw-yuv, width=(int)$WIDTH, height=(int)$HEIGHT, framerate=(fraction)24/1"
VCAPS2="video/x-raw-yuv, width=(int)640, height=(int)480, framerate=(fraction)24/1"
CONV="queue ! videorate ! $VCAPS2"
ENCODE="ffmpegcolorspace ! x264enc speed-preset=ultrafast sliced-threads=true threads=8 ! avimux ! filesink location=rtp-4k-h264.avi"

# this adjusts the latency in the receiver
LATENCY=0

gst-launch-0.10 -v gstrtpbin name=rtpbin latency=$LATENCY         \
     udpsrc caps=$CAPS port=$PORT ! rtpbin.recv_rtp_sink_0        \
       rtpbin. ! rtpvrawdepay ! xvimagesink

