#!/bin/bash
#
# Script to capture X screen, encode to H.264 and send via RTP.
# @author Andrew Ford
# Usage: ./gst-server-screencap-h264-rtp.sh [destination ip] [destination port] [name]

# Destination ip/port
DEST=$1
PORT=$2
RTCPPORT=$(($2+1))

VELEM="ximagesrc startx=0 starty=0 endx=320 endy=240 use-damage=false"
VCAPS="video/x-raw-rgb, bpp=(int)32, depth=(int)24, endianness=(int)4321, red_mask=(int)65280, green_mask=(int)16711680, blue_mask=(int)-16777216, width=(int)320, height=(int)240, framerate=(fraction)60/1"
VENC="x264enc speed-preset=2 tune=zerolatency sliced-threads=false threads=4 intra-refresh=true byte-stream=true bitrate=5000 key-int-max=100 vbv-buf-capacity=300 me=1 trellis=false cabac=false"

VSOURCE="$VELEM ! $VCAPS ! queue ! videorate ! ffmpegcolorspace ! $VENC ! rtph264pay"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"
SDES="sdes-cname=$3"

gst-launch-0.10 -v gstrtpbin latency=10000 name=rtpbin $SDES \
    $VSOURCE ! queue ! rtpbin.send_rtp_sink_0                \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK            \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK                  \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0
