export DISPLAY=:0
cd /home/user
#./Gravstart.sh -update
./Gravstart.sh -k
cd /home/user/grav
./grav-20101025 -am -t -fs -vsr -avsr 120 224.2.224.225/20002 233.17.33.212/50012 &>>/dev/null &

