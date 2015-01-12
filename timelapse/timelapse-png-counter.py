#!/usr/bin/python

import os
import sys

if len(sys.argv) != 2:
    print 'Wrong number of args (needs 1)\nUsage: timelapse-png-counter.py [dir]'
    exit()

ls = os.listdir(sys.argv[1])

for dirs in ls:
    try:
        subpath = os.path.join(sys.argv[1], dirs)
        print subpath + ': ',
        files = os.listdir(subpath)
        count = 0
        for file in files:
            if len(file) > 4 and file[-4:] == '.png':
                count = count + 1
        print count
    except:
        import traceback
        traceback.print_exc()
        print dirs + ' probably not a directory'

