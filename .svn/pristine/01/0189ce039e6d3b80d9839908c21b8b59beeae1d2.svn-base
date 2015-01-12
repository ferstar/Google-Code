#!/bin/bash
#
# Test script for H.264 RTP loopback.
# @author Andrew Ford

VELEM="filesrc location=$1 ! matroskademux"

VSOURCE="$VELEM ! rtph264pay ! rtph264depay"

VOUT="ffdec_h264 ! xvimagesink"

gst-launch-0.10 -v $VSOURCE ! $VOUT

