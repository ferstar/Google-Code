#!/bin/bash
#
# Script for sending V4L2 + audio from pulse as H264/AAC in an MPEG transport
# stream container over UDP.
# @author Andrew Ford
# Usage: gst-server-v4l2-pulse-h264-aac-mpegts.sh [device] [width] [height]
#        [bitrate] [host] [port]

DEVICE=$1
WIDTH=$2
HEIGHT=$3
BITRATE=$4
DEST=$5
PORT=$6

VELEM="v4l2src device=$DEVICE"
VCAPS="video/x-raw-yuv,width=(int)$WIDTH,height=(int)$HEIGHT,framerate=30/1,format=(fourcc)I420"
VENC="x264enc speed-preset=2 tune=zerolatency sliced-threads=false bitrate=$BITRATE key-int-max=100 threads=4 byte-stream=true"
ACAPS="audio/x-raw-int,channels=(int)2"
AELEM="pulsesrc ! $ACAPS ! audioconvert ! faac"

gst-launch-0.10 -v $VELEM ! $VCAPS ! $VENC ! queue ! mpegtsmux name=mux \
                   $AELEM ! mux. \
                   mux. ! udpsink host=$DEST port=$PORT

