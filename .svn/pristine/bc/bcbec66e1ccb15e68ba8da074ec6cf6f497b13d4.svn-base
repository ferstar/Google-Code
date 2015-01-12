#!/bin/bash
# switch tabs in firefox
# Author:  Ralph Bean <rjbpop@rit.edu>

export DISPLAY=:0

# Get the window id of firefox
ffID=$(xdotool search --onlyvisible --class firefox)
xdotool windowfocus $ffID
xdotool key Ctrl+r
