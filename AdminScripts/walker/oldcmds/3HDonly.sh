#!/bin/bash
./Gravstart.sh -k
export DISPLAY=:0
cd /home/user/grav
./grav-20110224 -am -t -vsr -fs -avsr 45 233.17.33.212/50012 233.17.33.224/50024 233.17.33.205/50002 & 2>&1 >>/dev/null&
#cd /home/user
#./Gravstart.sh -f
