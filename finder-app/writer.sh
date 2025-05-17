#!/bin/bash

if ["$#" -ne 2]; then
    echo "Error: Two arguments required."
    echo "Usage: $0 <writefile> <writestr"
    exit 1
fi

writefile=$1
writestr=$2

writedir=$(dirname "$writefile")

if ! mkdir -p "$writedir"; then
    echo "Error: Could not create directory path $writedir."
    exit 1
fi

if ! echo "$writestr" > "$writefile"; then
    echo "Error: Could not write to file $writefile."
    exit 1
fi

echo "Successfully wrote to file $writefile"

exit 0