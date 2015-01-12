#!/bin/bash
#Move all previous logs, execute prepStreams and the transcodeManager scripts.
#Meant to bring the streaming service back from a cold state.

cd /var/www/stream-ctl
mv logs/log-transcodeManager.log logs/log-transcodeManager.log.`date`
echo "moved transcoder manager log"
mv logs/streamLive.logs logs/streamLive.logs.`date +%y.%m.%d.%H.%M.%S`
mkdir logs/streamLive.logs
rm -f logs/streamLive.logs/*
echo "moved stremlive logs"
./prepStreams.pl
echo "preped streams";
./transcodeManager.pl &
echo "done"

