#!/bin/bash
#
# Script for transcoding H.264 video over multicast RTP.
# @author Andrew Ford
# Usage: ./gst-rtp-h264-view.sh [source ip] [source port] [width] [height] [bitrate] [dest ip] [dest port] [name]

function help {
	echo "Usage: ./gst-rtp-h264.sh [-sip] [-sport] [-dip] [-dport] [-name] ([-br] [-width] [-height] [-threads] [-h])"
	echo ""
	echo "-sip		Source IP"
	echo "-sport		Source Port"
	echo "-dip		Destination IP"
	echo "-dport		Destination Port"
	echo "-name		Stream name (single stream, no spaces"
	echo ""
	echo "-br		Bitrate (kilobytes); default is 5000"
	echo "-width		Transcoded stream width"
	echo "-height		Transcoded stream height"
	echo "-threads	Number of threads to use"
	echo "-h		Help"
}

#Default number of threads to use
THREADS=2
if [ $# -eq 0 ]; then
	help
	exit
fi

while [ $# -gt 0 ]
do
	case $1 in
	
	#Multicast source IP
	-sip)
		SOURCE=$2
		shift 2
	;;
	#Multicast source port
	-sport)
		SOURCEPORT=$2
		shift 2
	;;
	-width)
		WIDTH=$2
		shift 2
	;;
	-height)
		HEIGHT=$2
		shift 2
	;;
	-br)
		BITRATE=$2
		shift 2
	;;
	-dip)
		DEST=$2
		shift 2
	;;
	-dport)
		DESTPORT=$2
		shift 2
	;;
	-name)
		NAME=$2
		shift 2
	;;	
	-threads)
		THREADS=$2
		shift 2	
	;;
	-h)
		help
		shift 1
		exit
	;;
	*)
		echo "Invalid usage"
		exit
	esac
done

if [ -z $SOURCE ]; then
	echo "Source IP not specified"; exit
fi
if [ -z $SOURCEPORT ]; then
	echo "Source port not specified"; exit
fi
if [ -z $BITRATE ]; then
	BITRATE=5000
	echo "Transcoded bitrate not specified"
	echo "The bitrate has been set to a default of $BITRATE"
fi
if [ -z $DEST ]; then
	echo "Destination IP not specified"; exit
fi
if [ -z $DESTPORT ]; then
	echo "Destination port not specified"; exit
fi
if [ -z $NAME ]; then
	echo "Name of stream not specified"; exit
fi

RTCPPORT=$(($SOURCEPORT+1))
DESTRTCPPORT=$(($DESTPORT+1))
#Adjust the scaling caps if width and height were specified
SCALECAPS="video/x-raw-yuv,width=(int)${WIDTH},height=(int)${HEIGHT}"
# this adjusts the latency in the receiver
LATENCY=0

# Proper video caps for H.264
VIDEO_CAPS="application/x-rtp,media=(string)video,clock-rate=(int)90000,encoding-name=(string)H264"
RECV="udpsrc caps=$VIDEO_CAPS port=$SOURCEPORT multicast-group=$SOURCE ! rtph264depay ! ffdec_h264"
ENCODE="x264enc speed-preset=2 tune=0x00000004 sliced-threads=false threads=$THREADS bitrate=$BITRATE qp-min=10 qp-max=20"

VRTPSINK="udpsink ttl-mc=127 port=$DESTPORT host=$DEST name=vrtpsink"
VRTCPSINK="udpsink ttl-mc=127 port=$DESTRTCPPORT host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=$RTCPPORT name=vrtpsrc"

# Width and height specified
if [ "$WIDTH" != "" -a "$HEIGHT" != "" ]; then
	gst-launch-0.10 -v gstrtpbin name=rtpbin sdes="application/x-rtp-source-sdes, name=(string)$NAME" \
		$RECV ! videoscale ! $SCALECAPS ! $ENCODE ! rtph264pay ! rtpbin.send_rtp_sink_0            \
	           rtpbin.send_rtp_src_0 ! $VRTPSINK      \
	           rtpbin.send_rtcp_src_0 ! $VRTCPSINK    \
		$VRTCPSRC ! rtpbin.recv_rtcp_sink_0
else
# Width and height were not specified
        gst-launch-0.10 -v gstrtpbin name=rtpbin sdes="application/x-rtp-source-sdes, name=(string)$NAME" \
                $RECV ! $ENCODE ! rtph264pay ! rtpbin.send_rtp_sink_0            \
                   rtpbin.send_rtp_src_0 ! $VRTPSINK      \
                   rtpbin.send_rtcp_src_0 ! $VRTCPSINK    \
                $VRTCPSRC ! rtpbin.recv_rtcp_sink_0
fi
