#!/bin/bash
#this script is dangerous it completely shuts down and restarts
#the live streaming system, but only brings up live streams on 
#the site, MAKE SURE YOU UNDERSTAND IT FIRST

echo "THIS SCRIPT IS DANGEROUS MAKE SURE YOU KNOW HOW IT WORKS (READ IT)"
    rm -f tcodemgr-*
    #TODO fix typo
    echo "sent stop msg to tcodemgr giving it time to stop"
    sleep 8 
    echo "transcode Manager should be stoped"
    rm -f ../html/queue/*
    echo "cleared queue"
     ./stopTranscoder.sh 
    echo "stopped transcoder" 
    mv logs/log-transcodeManager.log logs/log-transcodeManager.log.`date`
    echo "moved transcoder manager log"
    mv logs/streamLive.logs logs/streamLive.logs.`date +%y.%m.%d.%H.%M.%S`
    mkdir logs/streamLive.logs
    rm -f logs/streamLive.logs/*
    echo "preped streams";
    ./prepStreams.pl 
    ./transcodeManager.pl &
    echo "done"
