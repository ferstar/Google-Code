#!/bin/bash
# Walking program to copy the active screen from the node specified to the root ScreenViewer Directory
# using SSH connections
# Usage: ./SCPWalker -l nodes_to_connect_to

function printhelp 
{
	echo "Usage: ./SCPWalker -l walk.list"
	echo ""
	echo "Script runs the provided script at each of the nodes on the provided list of nodes"
	echo "-h	print out help"
	echo "-l 	pass in list of nodes"
}

function walker {
	#read in list of nodes to walk
	echo "#######################"
	echo "Reading $Nodes"
	n=0
	while read line
	do
        	nodes[$n]=$line
        	#echo "$n = $line"
        	n=$[$n + 1]
	done < $Nodes
	#echo ${nodes[*]}
	echo "#######################"
	echo "Done reading $Nodes"
	#read in command list
	#echo "Reading $Cmds"
	#c=0
	#while read line
	#do
	#       cmd[$c]=$line
	#       echo "$c = $line"
	#       c=$[$c + 1]
	#done < $Cmds
	#echo ${cmd[*]}
	#echo "Done reading $Cmds"

	#iterate through list of nodes
	echo "#######################"
	echo "Starting to walk..."
	for node in ${nodes[@]}
	do

	        echo "-----------------------------------------"
	        echo "-----------------------------------------"
	        echo "Running for $node"
	        echo "----------------------"
	        scp ${node}:/tmp/screen.png /root/screenViewer/${node}.png
	        #exit
	done
	echo "#######################"
	echo "Finished walking."
	echo "#######################"
}
Nodes=""
Cmds=""
while [ $# -gt 0 ]
do
	case $1
	in

	-h)
		#print useage information
		printhelp
		exit
	;;
	-l)
		#filename for script to run
		Nodes=$2
		shift 2
	;;
	esac
done
LOG=AGWalker-$(date +%Y%m%d-%H:%M)
walker 2>&1 | tee -a /var/log/AGWalker/$LOG.log
