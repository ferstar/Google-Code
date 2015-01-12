#!/bin/bash
wmctrl -r grav -b add,skip_taskbar
wmctrl -r grav -e 0,0,0,1024,1024 
xdotool mousemove 120 30
xdotool mousedown 1
xdotool mousemove 1700 100
xdotool mouseup 1
wmctrl -r grav -e 0,0,0,4048,1024



