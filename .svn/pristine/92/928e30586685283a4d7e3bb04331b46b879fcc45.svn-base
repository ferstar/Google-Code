#!/usr/bin/python
#
# Script for receiving MJPG video over HTTP, transcoding to H.264, and sending
# to a unicast or multicast address via RTP.
# @author Andrew Ford
# Usage: ./gst-server-http-mjpg-to-rtp-h264.py [URL] [dest IP/port] [name]

import gobject
import pygst
pygst.require("0.10")
import gst
import sys

usage = "Usage: ./gst-server-http-mjpg-to-rtp-h264.py [URL] [dest IP/port] [name]"

if len(sys.argv) != 4:
    print "ERROR: wrong number of arguments"
    print usage
    sys.exit(2)

mjpgSource = sys.argv[1]
destination = sys.argv[2]
sdesName = sys.argv[3]

if destination.count("/") != 1:
    print "ERROR: destination address must be formatted ip/port"
    sys.exit(2)

destAddress = destination.split("/")[0]
destPort = int(destination.split("/")[1])
rtcpPort = destPort + 1

print "Attempting to transcode " + mjpgSource + " to RTP/H.264 on " + \
      str(destAddress) + "/" + str(destPort)

pipe = gst.Pipeline("HTTP-RTP")
mainLoop = gobject.MainLoop()

# make & setup HTTP input element
souphttpsrc = gst.element_factory_make("souphttpsrc", "souphttpsrc")
souphttpsrc.set_property("location", mjpgSource)
souphttpsrc.set_property("blocksize", 8192)
souphttpsrc.set_property("do-timestamp", True)

# make video elements
jpegdec = gst.element_factory_make("jpegdec", "jpegdec")
x264enc = gst.element_factory_make("x264enc", "x264enc")

x264enc.set_property("threads", 0)
x264enc.set_property("byte-stream", True)
x264enc.set_property("bitrate", 2500)
x264enc.set_property("key-int-max", 100)
x264enc.set_property("vbv-buf-capacity", 300)
x264enc.set_property("me", 1)
x264enc.set_property("trellis", False)
x264enc.set_property("cabac", False)

# make RTP/UDP output elements
rtpbin = gst.element_factory_make("gstrtpbin", "gstrtpbin")
rtph264pay = gst.element_factory_make("rtph264pay", "rtph264pay")
queue = gst.element_factory_make("queue", "queue")

udpsinkRTP = gst.element_factory_make("udpsink", "udpsinkRTP")
udpsinkRTP.set_property("host", destAddress)
udpsinkRTP.set_property("port", destPort)
udpsinkRTP.set_property("ttl-mc", 127)

udpsinkRTCP = gst.element_factory_make("udpsink", "udpsinkRTCP")
udpsinkRTCP.set_property("host", destAddress)
udpsinkRTCP.set_property("port", rtcpPort)
udpsinkRTCP.set_property("ttl-mc", 127)
udpsinkRTCP.set_property("sync", False)
udpsinkRTCP.set_property("async", False)

# set sdes
sdes = rtpbin.get_property("sdes")
sdes.set_value("name", sdesName)
rtpbin.set_property("sdes", sdes)

# setup the pipeline
pipe.add(souphttpsrc, jpegdec, x264enc, queue, udpsinkRTP, udpsinkRTCP,
         rtpbin, rtph264pay)

gst.element_link_many(souphttpsrc, jpegdec, x264enc, queue, rtph264pay)

rtph264pay.link_pads("src", rtpbin, "send_rtp_sink_0")
rtpbin.link_pads("send_rtp_src_0", udpsinkRTP, "sink")
rtpbin.link_pads("send_rtcp_src_0", udpsinkRTCP, "sink")

pipe.set_state(gst.STATE_PLAYING)
print "Waiting for pipeline state..."
pipe.get_state()

print "Now running..."
mainLoop.run()

