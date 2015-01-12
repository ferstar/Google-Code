#!/bin/bash
export DISPLAY=:0

su user
cd /home/user/grav
pkill grav
./grav-20110224 -t -fs 224.2.224.225/20002 &>>/dev/null&
exit
