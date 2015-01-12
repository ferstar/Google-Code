export DISPLAY=:0
cd /home/user
#./Gravstart.sh -update
./Gravstart.sh -k
cd /home/user/grav
./grav-20110224 -ht "Live from National Library of Medicine (view locally in 07B-2271)" -am -t -fs 224.2.224.113/20002 233.17.33.224/50024 &>>/dev/null &

