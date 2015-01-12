#!/bin/bash
#
# Script to capture X screen, encode to H.264 and write to AVI.
# @author Andrew Ford
# Usage: ./gst-screencap-encode.sh [width] [height] [framerate] [bitrate] [file]

# width/height
WIDTH=$1
HEIGHT=$2
$FPS=$3
$BITRATE=$4

VELEM="ximagesrc startx=0 starty=0 endx=$WIDTH endy=$HEIGHT use-damage=false"
VCAPS="video/x-raw-rgb, bpp=(int)32, depth=(int)24, endianness=(int)4321, red_mask=(int)65280, green_mask=(int)16711680, blue_mask=(int)-16777216, width=(int)$WIDTH, height=(int)$HEIGHT, framerate=(fraction)$3/1"
VENC="x264enc threads=4 byte-stream=true bitrate=$4 me=1 trellis=false cabac=false"

VSOURCE="$VELEM ! $VCAPS ! queue ! videorate ! ffmpegcolorspace ! $VENC ! avimux ! filesink location=$5"

gst-launch-0.10 -v $VSOURCE

