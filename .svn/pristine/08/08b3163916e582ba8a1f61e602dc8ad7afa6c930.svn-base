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
CAPS="application/x-rtp,media=(string)video,clock-rate=(int)90000,sampling=(string)YCbCr-4:2:0,width=(string)$WIDTH,height=(string)$HEIGHT"
SCALECAPS="video/x-raw-yuv, width=(int)1920, height=(int)1080"

# this adjusts the latency in the receiver
LATENCY=0

gst-launch-0.10 -v gstrtpbin name=rtpbin latency=$LATENCY                          \
     udpsrc caps=$CAPS port=$PORT ! rtpbin.recv_rtp_sink_0                         \
       rtpbin. ! queue ! rtpvrawdepay ! queue ! ffmpegcolorspace ! cacasink     \
     udpsrc port=$RTCPPORT ! rtpbin.recv_rtcp_sink_0                               \
         rtpbin.send_rtcp_src_0 ! udpsink port=$RTCPPORT host=$DEST sync=false async=false

