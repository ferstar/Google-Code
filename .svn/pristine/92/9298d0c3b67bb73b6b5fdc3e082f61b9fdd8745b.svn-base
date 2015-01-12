#!/usr/bin/bash
#Kills all existing transcoding processes, and then brings all processes back up similar to restart.sh,
#But transcodes the polisseni center 1 and 2 streams on thrasher instead of pelican. 

#Kill all existing transcoding processes
ssh -n root@pelican-00 pkill -9 gst-launch-0.10
#transcode streams on testamajig instead of pelican
./prepBackupStreams.pl
