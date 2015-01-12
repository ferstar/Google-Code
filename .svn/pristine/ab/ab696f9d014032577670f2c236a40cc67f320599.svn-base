#!/bin/bash
#
# Script for serving raw UYVY video via RTP.
# @author Andrew Ford
# Usage: ./gst-server-uyvy-raw-rtp.sh [filename] [width] [height] [framerate] [destination ip] [destination port]

WIDTH=$2
HEIGHT=$3
FRAMERATE=$4

# Destination address
DEST=$5
PORT=$6
RTCPPORT=$(($6+1))

VELEM="filesrc location=$1 ! videoparse format=10 width=$WIDTH height=$HEIGHT framerate=$FRAMERATE ! queue"
VCAPS="video/x-raw-yuv, width=(int)$WIDTH, height=(int)$HEIGHT, format=(fourcc)RGBA"

VSOURCE="$VELEM ! rtpvrawpay mtu=8950"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"

gst-launch-0.10 -v gstrtpbin name=rtpbin  \
    $VSOURCE ! rtpbin.send_rtp_sink_0     \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK

