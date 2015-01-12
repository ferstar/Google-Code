#!/bin/bash
#
# Script for decoding a file, reencoding as H.264 video and sending via RTP.
# @author Andrew Ford
# Usage: ./gst-server-testpattern-h264-rtp.sh [filename] [bitrate] [destination ip] [destination port] [name]

# Destination multicast address
DEST=$3
PORT=$4
RTCPPORT=$(($4+1))

VELEM="filesrc location=$1 ! decodebin"
VENC="x264enc speed-preset=1 sliced-threads=false threads=8 byte-stream=true bitrate=$2 key-int-max=100 cabac=false"
VSOURCE="$VELEM ! ffmpegcolorspace ! queue ! videorate ! $VENC ! rtph264pay"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"
SDES="sdes-cname=$5"

gst-launch-0.10 -v gstrtpbin name=rtpbin $SDES    \
    $VSOURCE ! queue ! rtpbin.send_rtp_sink_0     \
        rtpbin.send_rtp_src_0 ! queue ! $VRTPSINK \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK       \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0

