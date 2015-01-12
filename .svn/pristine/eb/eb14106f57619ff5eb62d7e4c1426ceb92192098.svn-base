#!/bin/bash
#
# Script to convert a video to mp4 (h264/aac) with 480p & 720p versions
# as well. (Input should be 1080p.)
# Requires ffmpeg w/ libx264 & libfaac support & MP4Box on the path.
#
# @author Andrew Ford
#
# Usage: avi-convert-to-mp4-multires.sh [filename]
#

FULLFILENAME=$1
LEN=${#1}
FILENAME=${FULLFILENAME:0:LEN-4}

ffmpeg -i $FULLFILENAME -vcodec copy -an $FILENAME-video.mp4
ffmpeg -i $FULLFILENAME -acodec libfaac -ac 2 -ab 192k $FILENAME-audio.aac

ffmpeg -i $FILENAME-video.mp4 -s hd720 -vcodec libx264 -threads 4 -vb 7000k -vpre libx264-medium -vpre libx264-main -an $FILENAME-video-720p.mp4
ffmpeg -i $FILENAME-video.mp4 -s 854x480 -vcodec libx264 -threads 4 -vb 2500k -vpre libx264-medium -vpre libx264-baseline -an $FILENAME-video-480p.mp4

MP4Box -add $FILENAME-video.mp4 -add $FILENAME-audio.aac -hint $FILENAME-1080p.mp4
MP4Box -add $FILENAME-video-720p.mp4 -add $FILENAME-audio.aac -hint $FILENAME-720p.mp4
MP4Box -add $FILENAME-video-480p.mp4 -add $FILENAME-audio.aac -hint $FILENAME-480p.mp4

