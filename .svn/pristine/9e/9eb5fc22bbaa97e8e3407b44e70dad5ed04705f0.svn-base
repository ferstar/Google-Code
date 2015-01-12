#!/bin/bash
#
# Script for transcoding H.264 video over multicast RTP.
# @author Andrew Ford
# Usage: ./gst-rtp-h264-view.sh [source ip] [source port] [bitrate] [dest ip] [dest port]

if [ $# -ne 5 ]; then echo "USAGE: ./script [source ip] [source port] [bitrate] [dest ip] [dest port]"; exit 1; fi

# Multicast source IP/port
SOURCE=$1
SOURCEPORT=$2
RTCPPORT=$(($2+1))

BITRATE=$3

DEST=$4
DESTPORT=$5

# this adjusts the latency in the receiver
LATENCY=0

# Proper video caps for H.264
VIDEO_CAPS="application/x-rtp,media=(string)video,clock-rate=(int)90000,encoding-name=(string)H264"
RECV="udpsrc caps=$VIDEO_CAPS port=$SOURCEPORT multicast-group=$SOURCE ! queue ! rtph264depay ! ffdec_h264 ! queue"
ENCODE="x264enc trellis=false cabac=false threads=4 bitrate=$BITRATE"

gst-launch-0.10 -v $RECV ! $ENCODE ! rtph264pay ! udpsink host=$DEST port=$DESTPORT
#gst-launch-0.10 $RECV ! fakesink
