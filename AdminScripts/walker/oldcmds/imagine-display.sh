#!/bin/bash

cd /home/user/grav

export DISPLAY=:0
echo "Display exported"

echo "running grav"
./grav-20110507 -vsr -avsr 45 224.2.224.225/20002 224.2.238.102/57020 233.17.33.230/50030 233.17.33.232/50032 233.17.33.234/50034 233.17.33.236/50036 233.17.33.238/50038 233.17.33.224/50024 233.17.33.228/50028 233.17.33.212/50012 233.17.33.205/50002 -ht "RIT Global Collaboration Grid" &>>/dev/null &
