#!/bin/bash

#Script used to test the set of processes that startvid uses
#Will run startvid.pl 30 times (given a 20 second runtime)
#Useage: ./testscript.sh

for i in {0..30..1}
	do
		./startvid.pl &
		sleep 20
		killall startvid.2.pl
done
