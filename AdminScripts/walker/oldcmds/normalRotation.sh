#!/bin/bash
cd /home/user/grav
pkill grav
pkill start.pl
./gravCMD.sh &>> /dev/null &
