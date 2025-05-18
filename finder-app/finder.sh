#!/bin/sh

if [ $# = 2 ]
then
	if [ -d "$1" ]
	then
		TotalFiles=$(find "$1" -type f | grep -c '^')
		LinesMatch=$(grep -ro "$2" "$1" | wc -l)
		echo "Valid Directory"
		echo "The number of files are $TotalFiles and the number of matching lines are $LinesMatch"
		exit 0
	else
		echo "not real"
		exit 1
	fi
else
	echo "ERROR: Invalid Number of Arguments. \r\n Total number of arguments should be 2."
	exit 1

fi
