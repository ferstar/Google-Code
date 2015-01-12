#!/bin/bash
#
# Script to capture X screen, encode to H.264, capture audio to avi.
# @author Andrew Ford
# Usage: ./gst-screencap-encode-with-audio-to-avi.sh [width] [height] [framerate] [bitrate] [filename without extension]

# note there are no queues in here - seem to cause serious mem leaks in this situation (multiple streams
# being muxed)

# width/height
WIDTH=$1
HEIGHT=$2
FPS=$3
BITRATE=$4

VELEM="ximagesrc startx=0 starty=0 endx=$WIDTH endy=$HEIGHT use-damage=false"
VCAPS="video/x-raw-rgb, bpp=(int)32, depth=(int)24, endianness=(int)4321, red_mask=(int)65280, green_mask=(int)16711680, blue_mask=(int)-16777216, width=(int)$WIDTH, height=(int)$HEIGHT, framerate=(fraction)$FPS/1"
VENC="x264enc speed-preset=3 byte-stream=true bitrate=$BITRATE me=1 trellis=false cabac=false"

VSOURCE="$VELEM ! $VCAPS ! videorate ! ffmpegcolorspace ! $VENC"
ASOURCE="pulsesrc ! audioconvert"

gst-launch-0.10 $VSOURCE ! mux. \
                   $ASOURCE ! mux. \
                   avimux name=mux ! filesink location=$5.avi

