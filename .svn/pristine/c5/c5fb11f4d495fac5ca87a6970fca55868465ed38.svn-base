#!/bin/bash
#
# Script for receiving MJPG video over HTTP, transcoding to H.264, and sending
# to a unicast or multicast address via RTP.
# @author Andrew Ford
# Usage: ./gst-server-http-mjpg-to-rtp-h264.sh [URL] [dest IP] [dest port] [name]

LOC=$1
DEST=$2
PORT=$3
RTCPPORT=$(($3+1))

VELEM="souphttpsrc location=$LOC blocksize=8192 do-timestamp=true ! jpegdec"
VENC="x264enc threads=0 byte-stream=true bitrate=2000 key-int-max=100 vbv-buf-capacity=300 me=1 trellis=false cabac=false ! queue ! rtph264pay"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"
SDES="sdes-cname=$4"

gst-launch-0.10 -v gstrtpbin latency=0 name=rtpbin $SDES \
    $VELEM ! $VENC ! rtpbin.send_rtp_sink_0              \
        rtpbin.send_rtp_src_0 ! $VRTPSINK                \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK              \
    $VRTCPSRC ! rtpbin.recv_rtcp_sink_0

