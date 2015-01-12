#!/bin/bash
# note this is only an example for the first stream

FILENAME="timelapse-`date +%Y%m%d`"

mencoder "mf:///mnt/bluearc-7k/IHST-timelapse-daily/IHST_233.17.33.205.50002*/*.png" -mf type=png:fps=30 -ovc x264 -of lavf -o /mnt/bluearc-7k/IHST-timelapse-videos/$FILENAME.h264
MP4Box -add /mnt/bluearc-7k/IHST-timelapse-videos/$FILENAME.h264 -fps 30 -hint /mnt/bluearc-7k/IHST-timelapse-videos/$FILENAME.mp4
rm /mnt/bluearc-7k/IHST-timelapse-videos/$FILENAME.h264

