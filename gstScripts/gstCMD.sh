#!/bin/bash
CHECK=`ps ax | grep gst-server | grep -v grep`
if [[ $CHECK == "" ]]; then
    echo "gst will run"
    python /home/user/gstScripts/gst-server-dv1394-usb-h264-rtp.py -a 224.2.224.225/20002 -n "RIT Building Institute Hall" &
else
    echo "gst already running"
    exit 0
fi

