#!/bin/bash

export DISPLAY=:0
cd /home/user/grav
pkill grav-20110224
./grav-20110224 -fs -t -am -avsr 40 -vsr 224.2.224.33/20002 233.17.33.224/50024 233.17.33.214/50014 &> /dev/null &

