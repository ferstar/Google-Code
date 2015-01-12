#!/bin/bash
#
# Script for receiving an MPEG2 stream via UDP and transcoding the video H.264 for RTP transmission.
# @author Andrew Ford
# Usage: ./gst-server-udp-mpeg-to-rtp-h264.sh [source ip:port] [dest video ip] [dest video port] [name]

# addresses
SRC=$1

VDEST=$2
VPORT=$3
VRTCPPORT=$(($3+1))

# H264 encode from the source
VELEM="udpsrc uri=$SRC ! queue ! flutsdemux name=fluts ! mpeg2dec ! queue ! videorate ! postproc_ffmpegdeint"
VENC="x264enc threads=0 byte-stream=true bitrate=2500 key-int-max=100 vbv-buf-capacity=300 me=1 trellis=false cabac=false ! rtph264pay"

VRTPSINK="udpsink port=$VPORT host=$VDEST name=vrtpsink"
VRTCPSINK="udpsink port=$VRTCPPORT host=$VDEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$VRTCPPORT name=vrtpsrc"
SDES="sdes-cname=$4"

gst-launch-0.10 -v gstrtpbin name=videobin $SDES      \
    $VELEM ! $VENC ! queue ! videobin.send_rtp_sink_0 \
        videobin.send_rtp_src_0 ! queue ! $VRTPSINK   \
        videobin.send_rtcp_src_0 ! $VRTCPSINK         \
      $VRTCPSRC ! videobin.recv_rtcp_sink_0

