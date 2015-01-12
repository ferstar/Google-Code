#!/bin/bash
#=========================================++
# ratStart.sh				  ||
# script to have a no-config rat set up   ||
# @author John Ganz			  ||
#=========================================++

# unmute mic
`sed -i "s/\("audioInputMute" *: *\).*/\1"0"/" /home/user/.RATdefaults` 

# scan for device names and change the value of audioDevice in .RATdefaults
DEVICE=`aplay -l | grep "USB Audio" | awk '{print $4}' | tr -cd [:alnum:]`
if [[ $DEVICE == "" ]]; then
	echo "Rat does not see a USB microphone"
else
	echo "device: $DEVICE"	
#	`sed -i "s/\("audioDevice" *: *\).*/\1"$DEVICE"/" /home/user/.RATdefaults` 
fi
# start rat if it is not running
CHECK=`pgrep rat-4.4`
if [[ $CHECK == "" ]]; then
    echo "Rat will run"
    export DISPLAY=:0
    #rat 233.17.33.100 50100 &
    rat $1 $2 &
else
    echo "Rat is running at PID $CHECK already"
    exit 0
fi
