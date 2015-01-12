#!/bin/bash
#
# Script for receiving and displaying H.264 video over multicast RTP.
# @author Andrew Ford
# Usage: ./gst-rtp-h264-view.sh [source ip] [source port]

# Multicast source IP/port
DEST=$1
PORT=$2
RTCPPORT=$(($2+1))

# this adjusts the latency in the receiver
LATENCY=0

# Proper video caps for H.264
VIDEO_CAPS="application/x-rtp,media=(string)video,clock-rate=(int)90000,encoding-name=(string)H264"

gst-launch-0.10 -v gstrtpbin name=rtpbin latency=$LATENCY                              \
     udpsrc caps=$VIDEO_CAPS port=$PORT multicast-group=$DEST ! rtpbin.recv_rtp_sink_0 \
       rtpbin. ! rtph264depay ! ffdec_h264 ! queue ! autovideosink         \
     udpsrc port=$RTCPPORT ! rtpbin.recv_rtcp_sink_0                                   \
         rtpbin.send_rtcp_src_0 ! udpsink port=$RTCPPORT host=$DEST sync=false async=false
