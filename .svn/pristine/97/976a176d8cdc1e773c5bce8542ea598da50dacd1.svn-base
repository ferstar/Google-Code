#!/bin/bash
export DISPLAY=:0

cd /home/user/grav

wget http://media.rc.rit.edu/gravbin/grav-20110224
chmod 755 grav-20110224
wget http://media.rc.rit.edu/gravbin/FreeSans.ttf
chmod 755 FreeSans.ttf

killall -r grav*

./grav-20110224 -am -t -fs -ga -vsr -avsr 45 224.2.224.225/20002
