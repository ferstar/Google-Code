#!/usr/bin/python
#================================================================================================================
# Multi-Destination gst-server-dv1394-h264-rtp.py
# @author John Ganz
#
#=================================================================================================================
import sys
import gobject
import pygst
pygst.require("0.10")
import gst

# create gstreamer pipeine, specifiy camera source and type for encoding to x264
mainLoop = gobject.MainLoop()
pipeline = gst.Pipeline("dv139-h264-rtp")
CAMERA = gst.element_factory_make("dv1394src", "dv1394src")
x264enc = gst.element_factory_make("x264enc", "x264enc")
dvdec = gst.element_factory_make("dvdec", "dvdec")
dvdemux = gst.element_factory_make("dvdemux", "dvdemux")
deint = gst.element_factory_make("deinterlace", "deinterlace")
bus = pipeline.get_bus()
def init():
        
        usage = "Usage: [texthostfile.txt] [Name]"
        if len(sys.argv) != 3:
		print usage
		sys.exit(2)
        f = sys.argv[1]
	SDES= str(sys.argv[2])
        
# make RTP/UDP output elements

        rtpbin = gst.element_factory_make("gstrtpbin", "gstrtpbin")
        rtph264pay = gst.element_factory_make("rtph264pay", "rtph264pay")
        queue = gst.element_factory_make("queue", "queue")
        ffmpegcolorspace = gst.element_factory_make("ffmpegcolorspace", "ffmpegcolorspace")
        interlace = gst.element_factory_make("deinterlace", "deinterlace")
        udpsinkRTP = gst.element_factory_make("multiudpsink", "udpsinkRTP")
        udpsinkRTCP = gst.element_factory_make("multiudpsink", "udpsinkRTCP")
	udpsinkRTCP.set_property("sync", False)
        udpsinkRTCP.set_property("async", False)

	file1 = open(f,'r')
	for line in file1:
		t = line.split(' ',2)
		DEST = t[0]
		PORT = int(t[1].rstrip('\r\n'))	
		RTCPPORT = int(PORT) + 1
		udpsinkRTP.emit("add", DEST,PORT)
		udpsinkRTCP.emit("add", DEST,RTCPPORT)

#ubuntu version 10.10 has more options than 9.1  
       
        if OScheck():
                x264enc.set_property("speed-preset", 1)
                x264enc.set_property("tune", 0x00000004)
                x264enc.set_property("sliced-threads", False)
                udpsinkRTP.set_property("ttl-mc", 127)
                udpsinkRTCP.set_property("ttl-mc", 127)
                x264enc.set_property("bitrate", 5000)
                x264enc.set_property("qp-min", 15)
                x264enc.set_property("qp-max", 30)
                x264enc.set_property("quantizer", 18)
        # Set SDES
                sdes = rtpbin.get_property("sdes")
                sdes.set_value("name", SDES)
                rtpbin.set_property("sdes", sdes)

# Encode from the dv1394 source

        x264enc.set_property("threads", 0)
        x264enc.set_property("byte-stream", True)        
        x264enc.set_property("key-int-max", 100)
        x264enc.set_property("vbv-buf-capacity", 300)
        x264enc.set_property("me", 1)
        x264enc.set_property("trellis", False)
        x264enc.set_property("cabac", False) 

# Setup the pipeline

        pipeline.add(CAMERA, dvdemux, dvdec, interlace, ffmpegcolorspace, deint, x264enc, queue, udpsinkRTP, udpsinkRTCP,rtpbin, rtph264pay)        
        gst.element_link_many(CAMERA, dvdemux)
        dvdemux.connect("pad-added", demuxer_callback)                                 
        gst.element_link_many(dvdec, interlace, ffmpegcolorspace, deint, x264enc, queue, rtph264pay)
                
        rtph264pay.link_pads("src", rtpbin, "send_rtp_sink_0")
        rtpbin.link_pads("send_rtp_src_0", udpsinkRTP, "sink")
        rtpbin.link_pads("send_rtcp_src_0", udpsinkRTCP, "sink")

# Callback for dynamic pad  
   
def demuxer_callback(demuxer, pad):
        print "Demuxer callback"
        dec264SinkPad = dvdec.get_pad("sink")
        pad.link(dec264SinkPad)
        print "Demuxer callback finished"

#check OS for specific settings

def OScheck():
        print "Checking Ubuntu Version..."      
        import re
        import os.path
        if os.path.exists('/etc/issue'):
                issue = open('/etc/issue','r')
                for line in issue.readlines():
                        version = re.search('10.10', line)
                        version2 = re.search('11.04', line)
                        if version:
                                print "Version 10.10..."        
                                return 1
                        if version2:
                                print "Version 11.04..."        
                                return 1
                        else:
                                print "Using default 9.10 settings..."
                                return 0
                issue.close()
        else:
                return 0

#main method to begin playback

def main():
        print "Waiting for pipeline state..."
        pipeline.set_state(gst.STATE_PLAYING)
        print "Now running..."
        mainLoop.run()
        
init()
print "Init finished"
main()
