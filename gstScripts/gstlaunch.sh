#!/bin/bash
#test and start script for gstreamer DV script
#just meant to test if DV script is running already, if so dont start

#gstpid="0"
#dvpid="0"

gstpid=`pgrep gst-launch`
dvpid=`pgrep server-dv1394`

#echo $gstpid
#echo $dvpid

if [[ -n $gstpid && -n $dvpid ]]
then
	echo "server-dv1394-H264-rtp.sh is already running"
else
	cd /home/user/
	./DVsend.sh
	echo "started dv script"
fi
