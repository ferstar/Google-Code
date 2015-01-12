#!/bin/bash
#
# Script for serving raw test video via RTP.
# @author Andrew Ford
# Usage: ./gst-server-raw-rtp.sh [width] [height] [destination ip] [destination port] [name]

WIDTH=$1
HEIGHT=$2

# Destination address
DEST=$3
PORT=$4
RTCPPORT=$(($4+1))

VELEM="videotestsrc pattern=16 kx=3 kt=6"
VCAPS1="video/x-raw-yuv, width=(int)320, height=(int)240, format=(fourcc)UYVY, framerate=(fraction)30/1"
VCAPS2="video/x-raw-yuv, width=(int)$WIDTH, height=(int)$HEIGHT, format=(fourcc)UYVY, framerate=(fraction)30/1"

VSOURCE="$VELEM ! $VCAPS2 ! rtpvrawpay mtu=8500"
#VSOURCE="$VELEM ! $VCAPS1 ! queue ! videorate ! videoscale method=0 ! $VCAPS2 ! rtpvrawpay mtu=8900"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
SDES="sdes-cname=$5"

gst-launch-0.10 -v gstrtpbin name=rtpbin $SDES    \
    $VSOURCE ! queue ! rtpbin.send_rtp_sink_0     \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK

