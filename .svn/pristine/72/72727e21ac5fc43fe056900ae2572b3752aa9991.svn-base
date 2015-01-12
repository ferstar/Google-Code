#!/bin/bash
#
# Script for serving a testpattern H.264 video via RTP.
# @author Andrew Ford
# Usage: ./gst-server-testpattern-h264-rtp.sh [destination ip] [destination port] [name]

# Destination multicast address
DEST=$1
PORT=$2
RTCPPORT=$(($2+1))

VELEM="videotestsrc pattern=16 kx2=5 ky2=500 kyt=-1"
VCAPS1="video/x-raw-yuv, width=(int)320, height=(int)180, framerate=(fraction)30/1"
VCAPS2="video/x-raw-yuv, width=(int)1920, height=(int)1080, framerate=(fraction)30/1"
VENC="x264enc speed-preset=1 sliced-threads=true threads=4 byte-stream=true bitrate=20000 key-int-max=100 cabac=false aud=false"
VSOURCE="$VELEM ! $VCAPS1 ! queue ! videorate ! videoscale ! $VCAPS2 ! $VENC ! rtph264pay config-interval=2"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"
SDES="sdes-cname=$3"

gst-launch-0.10 -v gstrtpbin name=rtpbin $SDES    \
    $VSOURCE ! queue ! rtpbin.send_rtp_sink_0     \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK       \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0

