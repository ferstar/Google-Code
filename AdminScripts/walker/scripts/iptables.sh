#!/bin/bash
iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport ssh -j LOG
iptables -A INPUT -p tcp --dport ssh -j ACCEPT --source 129.21.0.0/16
iptables -A INPUT -p tcp --dport ssh -j DROP
