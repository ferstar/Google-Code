#!/usr/bin/python
#================================================================================================================
# gst-server dv1394 & usb to h264-rtp
# defaults to dv
# python gst-server-dv1394-usb-h264-rtp.py --help for help
# depends on Argparse
# @author John Ganz
#=================================================================================================================
import sys
import gobject
import pygst
pygst.require("0.10")
import gst

# create gstreamer pipeine, specifiy camera source and type for encoding to x264
mainLoop = gobject.MainLoop()
pipeline = gst.Pipeline("dv139/USB-h264-rtp")
DVCAMERA = gst.element_factory_make("dv1394src", "dv1394src")
USBCAMERA = gst.element_factory_make("v4l2src", "v4l2src")

# usb elements - none of which are ever utilized
caps = gst.Caps("video/x-raw-yuv,format=(fourcc)AYUV,width=1080,height=1920,framerate=30")
capsFilter = gst.element_factory_make("capsfilter", "filter")
capsFilter.set_property("caps", caps)
videorate = gst.element_factory_make("videorate", "videorate")

# dv elements
dvdec = gst.element_factory_make("dvdec", "dvdec")
dvdemux = gst.element_factory_make("dvdemux", "dvdemux")

# RTP/UDP output elements
rtpbin = gst.element_factory_make("gstrtpbin", "gstrtpbin")
rtph264pay = gst.element_factory_make("rtph264pay", "rtph264pay")
queue = gst.element_factory_make("queue", "queue")
ffmpegcolorspace = gst.element_factory_make("ffmpegcolorspace", "ffmpegcolorspace")
udpsinkRTP = gst.element_factory_make("udpsink", "udpsinkRTP")
udpsinkRTCP = gst.element_factory_make("udpsink", "udpsinkRTCP")

# econoding settings
x264enc = gst.element_factory_make("x264enc", "x264enc")
deint = gst.element_factory_make("deinterlace", "deinterlace")
bus = pipeline.get_bus()

# parse arguments, call methods with the given values
# calls setRTP, encodingPresets, pipe
def argParse():
	import argparse
	parser = argparse.ArgumentParser(description='DV or USB device to h264')	
	parser.add_argument('-b','--bitrate',help='Set bitrate  to -b #', required=False, dest='bit', default=5000)
	parser.add_argument('-w','--width', help='Set resoultion width to -w #', required=False, dest='width', default=1080)
	parser.add_argument('-l','--length',help='Set resoultion height to -l #', required=False, dest='length', default=1920)
	parser.add_argument('-f','--framerate',help='Set video framerate to -f #', required=False, dest='frames', default=30)
	parser.add_argument('-a','--address',help='Destination -a ip/port', required=False, dest='addr', default='224.2.224.225/20002')
	parser.add_argument('-n','--name', help='Set RTP name to -n name', required=False, dest='name', default='User')
	parser.add_argument('-s','--speedpreset',help='Set speed preset to -s #', required=False, dest='sp', default='1')
	parser.add_argument('-ag','--accessgrid', help='Grab destitation from AG', action='store_true', default=False)
	parser.add_argument('-usb','--usbcam', help='Use USB-camera', action='store_true', default=False)
	parser.add_argument('-dv','--dv', help='Use DV-camera', action='store_true', default=True)			
	args = parser.parse_args()
	
	if not args.accessgrid:
		socket = args.addr.split('/',1)
		setRTP(socket[0], socket[1])		
	else:
		t1, t2 = AGgrab()
		setRTP(t1, t2)
	encodingPresets(args.name, int(args.bit), int(args.sp))
	pipe(args.usbcam)

# make RTP/UDP output elements
def setRTP(DEST, PORT):	
	PORT = int(PORT)
	udpsinkRTP.set_property("host", DEST)
	udpsinkRTP.set_property("port", PORT)	
	deint.set_property("fields",1)
	udpsinkRTCP.set_property("host", DEST)
	RTCPPORT = int(int(PORT)+1)	
	udpsinkRTCP.set_property("port", RTCPPORT)
	udpsinkRTCP.set_property("sync", False)
	udpsinkRTCP.set_property("async", False)

def encodingPresets(SDES, BIT, SP):
# Encode from the dv1394 source
        x264enc.set_property("threads", 1)
        x264enc.set_property("byte-stream", True)        
        x264enc.set_property("key-int-max", 100)
        x264enc.set_property("vbv-buf-capacity", 300)
        x264enc.set_property("me", 1)
        x264enc.set_property("trellis", False)
        x264enc.set_property("cabac", False) 	

	#ubuntu version 10.10 has more options than 9.1  
	if OScheck():           
		x264enc.set_property("speed-preset", SP)
                x264enc.set_property("tune", 0x00000004)
                x264enc.set_property("sliced-threads", False)
                udpsinkRTP.set_property("ttl-mc", 127)
                udpsinkRTCP.set_property("ttl-mc", 127)
                x264enc.set_property("bitrate", BIT)
                x264enc.set_property("qp-min", 15)
                x264enc.set_property("qp-max", 25)
                x264enc.set_property("quantizer", 18)
       		# Set SDES
                sdes = rtpbin.get_property("sdes")
                sdes.set_value("name", SDES)
                rtpbin.set_property("sdes", sdes)	

# grabs streams from AG - AGTools needs to be in working directory 
def AGgrab():
	import os, sys
	lib_path = os.path.abspath('/home/user/grav/py')
	sys.path.append(lib_path)
	import AGTools	
	client = AGTools.GetFirstValidClientURL()
	goal = AGTools.GetFormattedVenueStreams(client,"video")
	for key, value in goal.items():
		sock = key.split('/',1)
		return sock[0], sock[1]		
		break

#check Version of Ubuntu
def OScheck():      
        import re
        import os.path
        if os.path.exists('/etc/issue'):
         issue = open('/etc/issue','r')
         for line in issue.readlines():
          version = re.search('10.10', line)
          version2 = re.search('11.10', line)
          if version or version2:
           return 1
          else:
           print "Using 9.10 settings..."
           return 0
         issue.close()
        else:
         return 0

# Setup the pipeline
def pipe(dev):
	if not dev:
        	pipeline.add(DVCAMERA, dvdemux, dvdec, ffmpegcolorspace, 
				deint, x264enc, queue, udpsinkRTP, udpsinkRTCP,rtpbin, rtph264pay)        
        	gst.element_link_many(DVCAMERA, dvdemux)
        	dvdemux.connect("pad-added", demuxer_callback)                                 
        	gst.element_link_many(dvdec, ffmpegcolorspace, deint, x264enc, queue, rtph264pay)
	else:
		pipeline.add(USBCAMERA, ffmpegcolorspace, deint, x264enc, queue, udpsinkRTP, udpsinkRTCP,rtpbin, rtph264pay)	
		gst.element_link_many(USBCAMERA, ffmpegcolorspace)		
		gst.element_link_many(ffmpegcolorspace, deint, x264enc, queue, rtph264pay)
		print "\n\nNow Streaming via USB" 
        rtph264pay.link_pads("src", rtpbin, "send_rtp_sink_0")
        rtpbin.link_pads("send_rtp_src_0", udpsinkRTP, "sink")
        rtpbin.link_pads("send_rtcp_src_0", udpsinkRTCP, "sink")

# Callback for dynamic pad    
def demuxer_callback(demuxer, pad):
        dec264SinkPad = dvdec.get_pad("sink")
        pad.link(dec264SinkPad)
	print "\n\nIgnore the error message, Now Streaming via DV" 
#main method to begin playback
def main():
        pipeline.set_state(gst.STATE_PLAYING)
        mainLoop.run()
        
argParse()
main()
