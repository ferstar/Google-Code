#/bin/bash

#@author Jason Wolanyk
#@version 08152012
#this script uses streamLive.pl to stop all streams being transcoded.
while [ `./streamLive.pl -list 2>/dev/null | wc -l` -gt 1 ]
do
echo `./streamLive.pl -list | cut -d' ' -f 1 | head -n 1 | tr - ' ' `
./streamLive.pl -kill `./streamLive.pl -list | cut -d' ' -f 1 | head -n 1 | tr - ' ' ` 
done
 