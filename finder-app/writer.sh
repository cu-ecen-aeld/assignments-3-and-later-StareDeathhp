#!/bin/sh
if [ $# = 2 ]
then
	
	mkdir -p "$(dirname "$1")"
	echo "$2" > "$1"
	exit 0

		
else
	echo "ERROR: Invalid Number of Arguments. \r\n Total number of arguments should be 2."
	exit 1

fi
