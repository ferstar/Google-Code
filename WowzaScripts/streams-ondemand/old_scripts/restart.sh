#!/bin/bash
#Kills all ongoing transcoding processes, 
#and then restarts specified streams for transcoding.

cd /var/www/stream-ctl
echo "stopping all existing transcoders"
sleep 1
./stopTranscoder.sh
echo "Beginning new transcoding streams"
sleep 1

#Pelican
#./streamLive.pl -tcode -f streams/Polisseni_Center_2 #default transcoder (Pelican)
#./streamLive.pl -tcode -f streams/Polisseni_Center_1 #default transcoder (Pelican)

#Ostrich kept locally in lab
./streamLive.pl -tcode -f streams/Smfl_Clean_Room -transcoder ostrich-04.rit.edu

#Ostrich kept in Wallace Center
./streamLive.pl -tcode -f streams/Rapid_Prototyping_Lab -transcoder ostrich-01.rit.edu

#Ostriches driving the CSI video Wall
#./streamLive.pl -tcode -f streams/Innovation_Floor -transcoder ostrich-11
#./streamLive.pl -tcode -f streams/Innovation_Overhead -transcoder ostrich-02

echo "Restarting Wowza Media Center"
/sbin/service WowzaMediaServer restart
