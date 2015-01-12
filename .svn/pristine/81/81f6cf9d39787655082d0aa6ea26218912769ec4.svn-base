#/bin/bash
while [ `./streamLive.pl -list 2>1 | wc -l` -gt 1 ]
do
./streamLive.pl -kill `./streamLive.pl -list | cut -d' ' -f 1 | head -n 1 | tr - ' ' `  
done
