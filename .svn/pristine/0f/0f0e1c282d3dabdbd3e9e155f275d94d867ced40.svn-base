#!/bin/bash

if[[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 255
fi

# Script to make puppet configure itself
puppet agent --waitforcert 60 --test
read -p "Press [Enter] once the certificate has been accepted on the puppetmaster"

# Poke the puppet agent to get the approved cert
puppet agent --waitforcert 60 --test

# Kick the puppet!
service puppet restart
