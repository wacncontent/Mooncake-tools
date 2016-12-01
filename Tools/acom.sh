#!/bin/bash

# Constants
ARTICLE_FILE_LIST="article_list.txt"
INCLUDE_FILE_LIST="include_list.txt"
ERROR_FILE="error.txt"
ARTICLE_RESULT="article_result.csv"

# Clear the screen
clear

# Print usage
if [ "$#" -ne 0 ]; then
	echo "Usage: $0"
	exit 0
fi

# Go to ACOM
if [ -d $ACOM ]; then
    cd $ACOM && echo "Change directory to ACOM Success."
else
    echo "$ACOM does not exists."
    exit 55
fi

# Clean old files
rm $ERROR_FILE 2>/dev/null
rm $ARTICLE_FILE_LIST 2>/dev/null
rm $INCLUDE_FILE_LIST 2>/dev/null
rm $ARTICLE_RESULT 2>/dev/null

# Get file list
find articles/ -type f -name "*.md" > $ARTICLE_FILE_LIST 2>/dev/null
find includes/ -type f -name "*.md" > $INCLUDE_FILE_LIST 2>/dev/null

if [ $? -eq 0 ]; then
	echo -e "\033[1;32m [OK] \033[1;0m Reading File List Done"
else
	echo -e "\033[1;31m [Error] \033[1;0m Reading File List Error!"
	exit 0
fi

# Start to process articles
echo -e "\033[1;33m Processing..\033[1;0m"

while read line;
do
	# Get ms.date
	date=$(grep -o -P 'ms.date=\".*?\"' "$line")
	# Get title
	title=$(grep -m 1 -o -P '^(\s*#)(\s+|[^#])(.*)$' "$line")

	# Error record
	if [ -z "$date" ] || [ -z "$title" ]; then
		echo "$line" >> $ERROR_FILE
	fi
	if [ -n "$date" ]; then
		date=$(echo $date | sed -e 's/ms.date=//g' -e 's/\"//g' -e 's/ //g')
	fi
    # Use $ as delimiter to prevent comma in title
	echo "${line}\$${title}\$${date}"
done < $ARTICLE_FILE_LIST > $ARTICLE_RESULT

# Convert unix to dos
unix2dos $ARTICLE_RESULT >/dev/null 2>&1
unix2dos $ERROR_FILE >/dev/null 2>&1

echo -e "\033[1;32m Done\033[1;0m"
