#!/bin/bash
# ----------------------------------------------+
#vicStart script				|
#						|
# Version 1.5 (John Ganz)			|
#	Changelog:				|
#	- Minor Bug Fixes			|
#	- support for new VIC binary            |
#     	- process awareness			|
#	- Background the GUI			|
# Version 1.0					|
#	Changelog:		        	|
#	- Genericized with the help             |
#         of Matt's GravStart script            |
#						|
# Written by: Dan Merboth                       |
#             Matthew Leszczenski               |
# 						|
# Usage:					|
# vicStart.sh [Node name] [IP] [Port] [Bitrate]	|
# ----------------------------------------------+

#set PATH
. /home/user/.profile

#sets for default display: Physically attached monitor
export DISPLAY=:0

CHECK=`pgrep vic-20110722`
if [[ $CHECK == "" ]]; then
    echo "Vic will run"
else
    echo "Vic is running at PID $CHECK already"
    exit 0

fi

if [[ $1 == -h ]]; then
	echo "Usage: vicstart-BlackMagic1080i.sh [Node name] [IP] [Port] [Bitrate]"
	echo "Version 1.5"
else

	#Need an if statement to check if the bitrate is between 0 and 50000.
	if [ $4 -gt 50000 ]; then
    		echo "ERROR: Bitrate must be between 0 and 50000. Setting bitrate to max."
    		$4=50000
	elif [ $4 -lt 1 ]; then
               echo "ERROR: Bitrate must be between 0 and 50000. Setting bitrate to 25000."
               $4=25000
        fi

	#Destination ip/port stolen from Andrew's gstreamer scripts
	DEST=$2
	PORT=$3

	cd /var/tmp/

	#Needs an if statement to check for /tmp/ on the file.
    	filename=vicStart-USB-$(date +%Y%m%d)

	configName=$(filename).vic

	echo "OUTPUT: Creating file: $configName..."

	#mkdir -p $filename
	#rm -f $filename

	#Make the file, start echoing output to it.
	echo "OUTPUT: Populating $filename with parameters..."
	echo "option add Vic.disable_autoplace true startupFile" > $configName
	echo "option add Vic.muteNewSources true startupFile" >> $configName
	echo "option add Vic.maxbw $4 startupFile" >> $configName
	echo "option add Vic.bandwidth $4 startupFile" >> $configName
	echo "option add Vic.framerate 30 startupFile" >> $configName #Should be 30.
	echo "option add Vic.quality 75 startupFile" >> $configName #
	echo "option add Vic.defaultFormat h264 startupFile" >> $configName
	echo "option add Vic.inputType NTSC startupFile" >> $configName
	echo "option add Vic.device \"V4L2:/dev/video0\" startupFile" >> $configName
	echo "option add Vic.defaultTTL 127 startupFile" >> $configName
	echo "option add Vic.rtpName \"$1\" startupFile" >> $configName #Uses the second arg for a node name
	echo "option add Vic.rtpEmail \"gurcharan.khanna@rit.edu\" startupFile" >> $configName #Default email

	echo "proc user_hook {} {" >> $configName
	echo "    global videoDevice inputPort transmitButton transmitButtonState sizeButtons inputSize" >> $configName
	echo "   update_note 0 \"gurcharan.khanna@rit.edu\" " >> $configName
	echo "    after 200 {" >> $configName
	echo "        if { ![winfo exists .menu] } {" >> $configName
	echo "            build.menu" >> $configName
	echo "        }" >> $configName
	echo "       set inputPort \"Camera 1\"" >> $configName
	echo "        grabber port \"Camera 1\"" >> $configName
	echo "        set inputSize 1" >> $configName
	echo "        set transmitButtonState 1" >> $configName
	echo "        transmit" >> $configName
	echo "    }" >> $configName
	echo "}" >> $configName

	echo "OUTPUT: $configName populated. Launching vic with: -u $filename $DEST/$PORT..."

	#Finish up, launch vic using this config with -u (filename)
	cd /home/user/vic
	cfg="/var/tmp/""$configName"
	./vic-20110722-ultrafast-zerolatency-singleframevbv-intrarefresh-deintmemfix-1010 -u $cfg $DEST/$PORT -C "V4L2:/dev/video0" &>> /home/user/vic/$filename.log &
	# wait for vic to launch, then place it behind any open windows	
	sleep 1
#	DS=`wmctrl -l | grep Blackmagic-Intensity | awk '{ if ( $2 ~ Blackmagic-Intensity) print $1 }'`
#	wmctrl -i -r $DS -b add,below
fi


