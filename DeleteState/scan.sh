#!/bin/bash

# Scan for files not exist in ACN
while read line;
do
    if [ ! -f $line ]; then
        echo "${line}"
    fi
done < $1 > notExistInACNFile.txt 

# Scan for deleted files
while read line;
do
    gitResult=$(git log -1 --name-status --date=short --pretty=format:"%cd" -- $line)
    if [[ ! -z "$gitResult" ]]; then
        # it's deleted
        echo "$gitResult"
    fi
done < notExistInACNFile.txt > gitResult.txt

rm notExistsFile.txt >/dev/null 2>&1

exit 0
