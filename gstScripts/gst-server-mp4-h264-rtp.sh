#!/bin/bash
#
# Script for serving an mp4 containing H.264 video via RTP.
# @author Andrew Ford
# Usage: ./gst-server-mp4-h264-rtp.sh [file] [destination ip] [destination port] [name]

# Destination multicast address
DEST=$2
PORT=$3
RTCPPORT=$(($3+1))

VELEM="filesrc location=$1 ! ffdemux_mov_mp4_m4a_3gp_3g2_mj2"

VSOURCE="$VELEM ! rtph264pay config-interval=5"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"
SDES="sdes-cname=$4"

gst-launch-0.10 -v gstrtpbin name=rtpbin $SDES    \
    $VSOURCE ! queue ! rtpbin.send_rtp_sink_0     \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK       \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0

