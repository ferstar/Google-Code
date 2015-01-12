#!/bin/bash
# maximize firefox.
# Author:  Ralph Bean <rjbpop@rit.edu>

# Get the window id of firefox
ffID=$(xdotool search --onlyvisible --class firefox)
for id in $ffID ; do 
	# Make it big
	xdotool windowsize  $ffID 2000 1000
done

