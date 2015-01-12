/bin/date

/bin/sleep 3

/bin/ps h -C $1 -o time,pid,cmd | /usr/bin/tee /tmp/allprocs$$.tmp | /bin/sort -r | /usr/bin/head -n -$2 | /bin/awk '{print $2}'| /usr/bin/tee /tmp/tokill$$.tmp| /bin/kill -9 - 2>/dev/null

/bin/echo "allprocs"
/bin/cat /tmp/allprocs$$.tmp

echo

/bin/echo "killed"
/bin/cat /tmp/tokill$$.tmp

echo
