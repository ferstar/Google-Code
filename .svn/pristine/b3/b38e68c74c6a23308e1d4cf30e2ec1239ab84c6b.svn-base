#!/bin/bash

ssh $1 "apt-get update"
ssh $1 "apt-get install scrot -y"
ssh $1 "echo \nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm7R+j3pHAC9F1e6kGYHl2awZfkM5fRtCMZvBcrtVXINTQC0Vr+nGsZnh5HoyecP94WfPqvJuJU89+6wwGNu42OfQMv4p2gEwoAxtpVjNGjy+Vm7LkJQQPhCwdC7nUtsiqh75ssN3aMy1PLsdDmVx9/q6OZJD6+5JUjDXiIelY8wt9SNyqLd53C/jTQtha4hJ8DwowdgwYatJBeuaNidn3g7hV6eLfACXEUTPXK7JmMQ8EMqWAIgtny0zKS/ssVD1jfUebK8keV1G14qRO/VlZZZW+uIOn+Ehv2D73vPVGx9WJrYakP1KX/17a5LDeUCarlgIGzpDHsQguwfdHf/BVw== root@lovelace" >> /home/user/.ssh/authorized_keys
ssh $1 "echo \nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm7R+j3pHAC9F1e6kGYHl2awZfkM5fRtCMZvBcrtVXINTQC0Vr+nGsZnh5HoyecP94WfPqvJuJU89+6wwGNu42OfQMv4p2gEwoAxtpVjNGjy+Vm7LkJQQPhCwdC7nUtsiqh75ssN3aMy1PLsdDmVx9/q6OZJD6+5JUjDXiIelY8wt9SNyqLd53C/jTQtha4hJ8DwowdgwYatJBeuaNidn3g7hV6eLfACXEUTPXK7JmMQ8EMqWAIgtny0zKS/ssVD1jfUebK8keV1G14qRO/VlZZZW+uIOn+Ehv2D73vPVGx9WJrYakP1KX/17a5LDeUCarlgIGzpDHsQguwfdHf/BVw== root@lovelace" >> /root/.ssh/authorized_keys
ssh $1 "su user -c \"export DISPLAY=:0; xhost +\";export DISPLAY=:0; xhost +SI:localuser:user; xhost +SI:localuser:root; xhost +SI:localuser:gdm; xhost -"
scp ./callScreen.pl root@$1:/home/user/callScreen.pl
ssh $1 "chmod 755 /home/user/callScreen.pl"
ssh $1 "chown user /home/user/callScreen.pl"
