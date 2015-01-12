#!/bin/bash
#
# Script to capture X screen, encode to H.264 and send via RTP.
# @author Andrew Ford
# Usage: ./gst-server-screencap-h264-rtp.sh [width] [height] [framerate] [bitrate] [destination ip] [destination port] [name]

# Destination ip/port
DEST=$5
PORT=$6
RTCPPORT=$(($6+1))

WIDTH=$1
HEIGHT=$2
FPS=$3
BITRATE=$4

VELEM="ximagesrc startx=0 starty=0 endx=$WIDTH endy=$HEIGHT use-damage=false"
VCAPS="video/x-raw-rgb, bpp=(int)32, depth=(int)24, endianness=(int)4321, red_mask=(int)65280, green_mask=(int)16711680, blue_mask=(int)-16777216, width=(int)$WIDTH, height=(int)$HEIGHT, framerate=(fraction)$FPS/1"
VENC="x264enc speed-preset=1 threads=4 byte-stream=true bitrate=$4 key-int-max=100 vbv-buf-capacity=300 me=1 trellis=false cabac=false"

VSOURCE="$VELEM ! $VCAPS ! videorate ! ffmpegcolorspace ! $VENC ! rtph264pay"

VRTPSINK="udpsink ttl-mc=127 port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink ttl-mc=127 port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"
SDES="sdes-cname=$7"

gst-launch-0.10 -v gstrtpbin latency=0 name=rtpbin $SDES \
    $VSOURCE ! queue ! rtpbin.send_rtp_sink_0                \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK            \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK                  \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0

