#!/bin/bash
#
# Script for capturing video from a v4l2 device, encoding to H.264, and
# sending via multicast RTP.
# @author Andrew Ford
# Usage: ./gst-server-v4l2-h264-rtp.sh [device] [width] [height] [framerate] [bitrate] [dest ip] [dest port] [name]

DEVICE=$1

# Destination ip/port
DEST=$6
PORT=$7
RTCPPORT=$(($7+1))

WIDTH=$2
HEIGHT=$3
FPS=$4
BITRATE=$5

# H264 encode from the source
VELEM="v4l2src device=$DEVICE"
VCAPS="video/x-raw-yuv,width=(int)$WIDTH,height=(int)$HEIGHT,framerate=(fraction)$FPS/1"
VSOURCE="$VELEM ! $VCAPS ! queue ! videorate ! ffmpegcolorspace ! queue"
VENC="x264enc speed-preset=1 tune=0x00000004 sliced-threads=false threads=1 byte-stream=true bitrate=$BITRATE key-int-max=100 vbv-buf-capacity=300 me=1 trellis=false cabac=false ! rtph264pay"

VRTPSINK="udpsink ttl-mc=127 port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink ttl-mc=127 port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"

gst-launch-0.10 -v gstrtpbin name=rtpbin sdes="application/x-rtp-source-sdes, name=(string)$8" \
    $VSOURCE ! $VENC ! rtpbin.send_rtp_sink_0  \
        rtpbin.send_rtp_src_0 ! $VRTPSINK      \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK    \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0

