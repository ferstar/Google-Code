#!/bin/bash
#
# Script for serving a testpattern H.264 video via RTP.
# @author Andrew Ford
# Usage: ./gst-server-testpattern-h264-rtp.sh [width] [height] [bitrate] [destination ip] [destination port] [name]

WIDTH=$1
HEIGHT=$2
BITRATE=$3

# Destination multicast address
DEST=$4
PORT=$5
RTCPPORT=$(($5+1))

VELEM="videotestsrc pattern=16 kx2=5 ky2=500 kyt=-1"
VCAPS1="video/x-raw-yuv, width=(int)320, height=(int)180, framerate=(fraction)30/1"
VCAPS2="video/x-raw-yuv, width=(int)$WIDTH, height=(int)$HEIGHT, framerate=(fraction)30/1"
VENC="x264enc speed-preset=1 sliced-threads=false threads=4 byte-stream=true bitrate=$BITRATE key-int-max=100 cabac=false"
VSOURCE="$VELEM ! $VCAPS1 ! queue ! videorate ! videoscale ! $VCAPS2 ! $VENC ! rtph264pay"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"

gst-launch-0.10 -v gstrtpbin name=rtpbin sdes="application/x-rtp-source-sdes, name=(string)$6"    \
    $VSOURCE ! queue ! rtpbin.send_rtp_sink_0     \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK       \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0

