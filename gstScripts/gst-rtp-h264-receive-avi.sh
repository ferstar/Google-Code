#!/bin/bash
#
# Script for receiving H.264 video over multicast RTP and saving to .avi.
# @author Andrew Ford
# Usage: ./gst-rtp-h264-view.sh [source ip] [source port] [filename]

# Multicast source IP/port
DEST=$1
PORT=$2
RTCPPORT=$(($2+1))

# this adjusts the latency in the receiver
LATENCY=0

# Proper video caps for H.264
VIDEO_CAPS="application/x-rtp,media=(string)video,clock-rate=(int)90000,encoding-name=(string)H264"

gst-launch-0.10 -v gstrtpbin name=rtpbin latency=$LATENCY                              \
     udpsrc caps=$VIDEO_CAPS port=$PORT ! rtpbin.recv_rtp_sink_0 \
       rtpbin. ! rtph264depay ! avimux ! filesink location=$3         \
     udpsrc port=$RTCPPORT ! rtpbin.recv_rtcp_sink_0                                   \
         rtpbin.send_rtcp_src_0 ! udpsink port=$RTCPPORT host=$DEST sync=false async=false

