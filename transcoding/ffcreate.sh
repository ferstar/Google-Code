#!/bin/bash
# Stephen Repetski
# RIT Research Computing
# Videos produced by our department are created mainly by a screencap program,
# where the display on a screen (1080p) is recorded. In order to turn this file
# of fairly limited use into something that can be accessed by all, we need to 
# transcode it into more useable formats. This script aims to transcode the
# file into three new versions, 1080, 720, and 480p.

if [ $# != 7 ] ; then
	echo "Usage: ./ffcreate.sh \$VIDEO \$PRESET \$Q1080 \$Q720 \$Q480 \$PROFILE \$OUTNAME"
	exit -1
fi

# Input video
VIDEO=$1
# Preset to use to transcode the video; default is superfast
PRESET=$2
# Bitrate of the 1080 version; default is 17500k
Q1080=$3
# Bitrate of the 720p version; default is 10000k
Q720=$4
# Bitrate of the 480p version; default is 5000k
Q480=$5
# Profile to use to transcode the video; default is 'baseline'
# Note: 'baseline' is only necessary for the 480p version, as that is what would
# most likely be used for mobile clients that don't support the 'main' or 
# higher profiles; if wanted, this can be increased to 'main' or another which
# would limit our support for iPad 1's, but would enable us to provide higher-
# quality video for other mobile clients using that version of the video
PROFILE=$6
# Name prefix of the output files
OUTNAME=$7

ffmpeg -i $VIDEO -vcodec libx264 -profile $PROFILE -preset $PRESET -psnr -ssim 1 -b:v $Q1080 -s hd1080 $OUTNAME-out-1080.mp4 -profile $PROFILE -b:v $Q720 -s hd720 $OUTNAME-out-720.mp4 -profile $PROFILE -b:v $Q480 -s hd480 $OUTNAME-out-480.mp4
