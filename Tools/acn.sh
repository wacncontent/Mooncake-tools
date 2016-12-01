#!/bin/bash

# Clear the screen
clear

# Constants
ARTICLE_FILE_LIST=$1
ERROR_FILE="error.txt"
ARTICLE_RESULT="article_result.csv"

# Clean old files
rm $ERROR_FILE 2>/dev/null
rm $ARTICLE_RESULT 2>/dev/null

while read line;
do
	if [ -e ${line} ]; then
		# Get title
		title=$(grep -m 1 -o -P '^(\s*#)(\s+|[^#])(.*)$' "$line")

		# Error record
		if [ -z "$title" ]; then
			echo "$line" >> $ERROR_FILE
		fi
	else
		title=""
		echo "$line" >> $ERROR_FILE
	fi
	echo "${line}\$${title}"
done < $ARTICLE_FILE_LIST > $ARTICLE_RESULT

# Convert unix to dos
unix2dos $ARTICLE_RESULT >/dev/null 2>&1
unix2dos $ERROR_FILE >/dev/null 2>&1

echo -e "\033[1;32m Done\033[1;0m"
