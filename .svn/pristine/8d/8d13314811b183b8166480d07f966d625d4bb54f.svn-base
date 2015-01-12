#!/bin/bash
#
# Script for capturing video from a dv1394 device, encoding to H.264, and
# sending via multicast RTP.
# @author Andrew Ford
# Usage: ./gst-server-dv1394-h264-rtp.sh [source ip] [source port] [name]

# Destination ip/port
DEST=$1
PORT=$2
RTCPPORT=$(($2+1))

# H264 encode from the source
VELEM="dv1394src ! dvdemux ! dvdec"
VCAPS="video/x-raw-yuv,width=720,height=480,framerate=30000/1001"
VSOURCE="$VELEM ! $VCAPS ! queue ! videorate ! ffmpegcolorspace ! postproc_ffmpegdeint ! videoflip method=2"
VENC="x264enc threads=1 byte-stream=true bitrate=2500 key-int-max=100 vbv-buf-capacity=300 me=1 trellis=false cabac=false ! rtph264pay"

VRTPSINK="udpsink port=$PORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink port=$RTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"
SDES="sdes-cname=$3"

#make pid file
touch /var/run/gst-launch.pid

gst-launch-0.10 -v gstrtpbin name=rtpbin $SDES \
    $VSOURCE ! $VENC ! rtpbin.send_rtp_sink_0  \
        rtpbin.send_rtp_src_0 ! $VRTPSINK      \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK    \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0 &

#send gst-launch's pid to file
PID=`echo $!`
echo $PID > /var/run/gst-launch.pid

