#!/bin/bash
# Cronjob to rotate between my projects.

while [ "1" -eq "1" ] ; do
    /home/user/bin/rjbpop-switch-tabs.sh
    /home/user/bin/rjbpop-reload-page.sh
    /home/user/bin/rjbpop-switch-back.sh
    sleep 5
    /home/user/bin/rjbpop-switch-tabs.sh
    
    sleep 420  # sleep for 7 minutes.
done
