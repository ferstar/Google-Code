#!/bin/bash
#
# Script for serving raw y4m video via RTP.
# @author Andrew Ford
# Usage: ./gst-server-y4m-raw-rtp.sh [filename] [width] [height] [destination ip] [destination port]

WIDTH=$2
HEIGHT=$3

# Destination address
DEST=$4
PORT=$5
RTCPPORT=$(($5+1))

VELEM="filesrc location=$1 ! ffdemux_yuv4mpegpipe ! queue"
VCAPS="video/x-raw-yuv, width=(int)$WIDTH, height=(int)$HEIGHT, format=(fourcc)I420"

# might not need caps due to demux figuring it out
VSOURCE="$VELEM ! rtpvrawpay mtu=8950"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
SDES="sdes-cname=$5"

gst-launch-0.10 -v gstrtpbin name=rtpbin $SDES    \
    $VSOURCE ! rtpbin.send_rtp_sink_0     \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK

