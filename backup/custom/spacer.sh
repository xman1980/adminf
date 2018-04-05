#!/bin/sh


# Settings
mode="count" # work mode: "space" or "count". 
minfreespace="2048" # Minimal free space in MB. Actual for "space" mode
count="31" # how many files stored. Actual for "count" mode
backupdir="/home/backup/custom" # directory to check

### Begin ###
echo "Mode $mode active"

# check OS
checkos=`uname -a | grep -c "FreeBSD"`

if [ $mode = "space" ]; then
    while [ `df -m $backupdir | grep dev | awk '{print $4}'` -lt $minfreespace ]
    do
	if [ $checkos = "1" ]; then
	    filetodelete=`find $backupdir -type f -exec stat -f "%Sm %N" -t %Y%m%d%H%M%S {} \; | sort -n | head -1 | cut -d' ' -f2`
    	    else
	    filetodelete=`find $backupdir -type f -exec stat -c "%Y %n" {} \; | sort -n | head -1 | cut -d' ' -f2`
	fi
    
	if [ -z $filetodelete ]; then
	    echo "No files found. Exit"
	    exit
	    else 
	    rm $filetodelete
	    echo "Deleted $filetodelete"
	fi
    done
fi

if [ $mode = "count" ]; then
    while [ `find $backupdir -type f | wc -l` -gt $count ]
    do
        if [ $checkos = "1" ]; then
            filetodelete=`find $backupdir -type f -exec stat -f "%Sm %N" -t %Y%m%d%H%M%S {} \; | sort -n | head -1 | cut -d' ' -f2`
            else
            filetodelete=`find $backupdir -type f -exec stat -c "%Y %n" {} \; | sort -n | head -1 | cut -d' ' -f2`
        fi

        if [ -z $filetodelete ]; then
            echo "No files found. Exit"
            exit
            else
            rm $filetodelete
            echo "Deleted $filetodelete"
        fi
    done
fi

echo "Check complete"
