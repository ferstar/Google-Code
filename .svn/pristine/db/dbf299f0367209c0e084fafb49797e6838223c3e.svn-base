#!/bin/bash
# this script should be called on boot to
# start whatever services are required for nodes 
# you should comment out any line that starts a 
# service that should not be running on the node 
logger "Running /home/user/systemScripts/startServices.sh"

#wait for the network to come up
sleep 25
# allow remote connections to X
export DISPLAY=:0
xhost + &>> /home/user/systemScripts/services.log &

#main Access Grid Venue
#VenueClient3.py --url https://vv3.mcs.anl.gov:8000/Venues/8cdd226521d429b68e7e8c0158a6a663 > /dev/null 2>&1 &>> /home/user/systemScripts/services.log &
#sleep 2

# Start RAT
/home/user/rat/ratCMD.sh &>> /home/user/systemScripts/services.log &
#sleep 2 


# Start Vic
/home/user/vic/vicCMD.sh &>> /home/user/systemScripts/services.log &
#sleep 2

# start DV or USB streaming
#/home/user/gstScripts/gstCMD.sh &>> /home/user/systemScripts/services.log &
#sleep 2 

#Start Grav
/home/user/grav/gravCMD.sh &>> /home/user/systemScripts/services.log &
logger "/home/user/systemScripts/startServiches.sh finished"
exit 0
