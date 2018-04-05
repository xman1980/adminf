#!/bin/sh
#$Id$
#Ansible managed: /home/anzzzible/adminf/ansible-hadoop/prod/roles/backup/templates/hmng01h2/backup.sh.j2 modified on 2015-03-24 10:50:21 by anzzzible on hadm01v1.hdc.dev1.adform.com

# sample backup script
# Last changes from: 27-07-2009

# Global backup tasks
mysql="YES" # need backup mysql bases? YES || NO
filebackup="YES" # need perform backup local files? YES || NO
savelocalbackup="YES" # need save backup on local drive? YES || NO
uploadbackup="YES" # need upload backup to FTP server? YES || NO
encryptbackup="NO" # need encrypt backup? YES || NO. If "YES" setup "encryptkey".
emailresult="NO" # need send e-mail with the results of backup? YES || NO. If "YES" setup "emailforresult".

# Common parametrs
backuptype="full" # 'full' or 'incremental'-files changed after last full backup
scriptdir="/site/backup/custom" # homedir of this script
backupdir="/mnt/data/1/backup/dmmn01h6/custom" # where save local backup
incfile="incfile" # file/dirs include to backup. Change content of this file
exfile="exfile" # file/dirs exclude from backup. Change content of this file
minfreespace="5120" # Minimal free space on backup slice in MB to start backup
encryptkey="" # Secret key to encrypt backup. Min 10 symbols recommended. Make sure that this key is kept in a safe place!
gpgpath="/usr/local/bin/" # path to gpg program
ftppath="/usr/bin/" # path to ftp client program
emailforresult="" # e-mail for backup results
sendmailpath="/usr/sbin/" # path to sendmail program

# FTP settings
#ftphost="" # backup host
#ftpuser=""
#ftppass=""
#ftpdir=""
ftphost="" # backup host
ftpuser=""
ftppass=""
ftpdir=""


# SQL settings
sqluser="root"
sqlpass=""
sqlhost="localhost"
allbases="YES" # 'YES' or 'NO'. Backup all bases or only from 'backupsqlbases' parametr
backupsqlbases="mysql" # bases list separate by space
mysqlutilspath="/usr/local/bin/" # path to 'mysql' and 'mysqldump' folder. No need to change.
sqldef="--single-transaction --skip-add-locks --skip-disable-keys --force" # parametrs for mysqldump


#######################
##### just do it! #####
#######################

salt=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8` # random string for more secure ftp uploads
freespace=`df -m $backupdir | grep -v ilesyste | awk '{print $4}'` # current free space on backupdir slice
hostn=`hostname`
backupstartdate=`date "+%Y-%m-%d %H:%M %Z%n"`

# check to exist backupdir
if [ ! -d $backupdir ];  then
   echo "$backupdir backupdir is no exist! Backup canceled."
   exit
fi

# check to exist mysql/mysqldump program
if [ $mysql = YES ]; then
    echo "Use mysql = yes"
    if [ ! -f $mysqlutilspath"/mysql" ];  then
	mysqlutilspath="/usr/bin/"
        if [ ! -f $mysqlutilspath"/mysqldump" ];  then
            echo "mysqldump program is not exist on this path $mysqlutilspath ! Backup canceled."
            exit
        fi
    fi
fi

# check to email setup
if [ $emailresult = YES ]; then
    echo "Send email = yes"
    if [ $emailforresult = "" ]; then
	echo "You should setup emailforresult parametr. Backup canceled."
	exit
    fi    
    
    if [ ! -f $sendmailpath"/sendmail" ];  then
	echo "You should setup sendmail before. Backup canceled."
	exit
    fi    
fi

# check to exist ftp client program
if [ $uploadbackup = YES ]; then
    echo "Check ftp client"
    if [ ! -f $ftppath"/ftp" ];  then
	ftppath="/usr/local/bin/"
        if [ ! -f $ftppath"/ftp" ];  then
            echo "FTP client program is not exist on this path $ftppath ! Backup canceled."
            echo "To install ftp client on CentOS/RHEL:"
            echo "yum install ftp"
            exit
        fi
    fi
    
    # remove old ftp logs
    if [ -f $scriptdir"/ftpdump.txt" ];  then
        rm $scriptdir"/ftpdump.txt"
    fi
fi

# check to free space on backupdir
if [ $minfreespace -ge $freespace ]; then
    echo "Free space not enought! Backup canceled."
    exit
fi

# check gpg and secret key
gpgext=""
if [ $encryptbackup = YES ]; then
    echo "Check gpg settings"
    if [ $encryptkey = "" ]; then
	echo "You must install the encryption key. Exit."
	exit
    fi    

    if [ ! -f $gpgpath"/gpg" ];  then
	gpgpath="/usr/bin/"
	if [ ! -f $gpgpath"/gpg" ];  then
	    echo "GnuPG v.1 is not found. You must setup path to GnuPG v.1 in gpgpath or setup GnuPG v.1."
	    echo "To setup GnuPG v.1 on FreeBSD use:"
	    echo "pkg_add -r gnupg1"
	    echo "or"
	    echo "cd /usr/ports/security/gnupg1 && make install"
	    echo ""
	    echo "To setup GnuPG v.1 on CentOS/RHEL use:"
	    echo "yum install gnupg"
	    echo ""
	    echo "Backup canceled."
	    exit
	fi
    fi
    gpgext=".gpg"
fi

# check OS
checkos=`uname -a | grep -c "FreeBSD"`

# if FreeBSD
if [ $checkos = "1" ]; then
    newerparam=" --newer-mtime-than "$scriptdir"/metka"
fi

# if Linux
if [ $checkos = "0" ]; then
    newerparam=" --newer "$scriptdir"/metka"
fi

if [ $backuptype = full ]; then
    newerparam=""
fi


incfile=$scriptdir"/"$incfile
exfile=$scriptdir"/"$exfile
curdate=`date "+%Y-%m-%d%n"`    
curdatewithhours=`date "+%Y-%m-%d-%H%n"`    

# get list of all mysql bases
if [ $mysql = YES ]; then
    echo "Get MySQL databases list"
    if [ $allbases = YES ]; then
	backupsqlbases=`echo "show databases"|$mysqlutilspath'mysql' --user=$sqluser --password=$sqlpass --host=$sqlhost|grep -v "^D"`
    fi
fi

# create remote current day folder
if [ $uploadbackup = YES ]; then
    echo "Create remote current day folder"
    ftp -i -n $ftphost 2>&1 1>>$scriptdir/ftpdump.txt <<END_SCRIPT
    quote USER $ftpuser
    quote PASS $ftppass
    mkdir $curdate
    quit
END_SCRIPT
fi


if [ ! -d $backupdir/$curdate ];  then
    echo "Creating "$backupdir/$curdate
    mkdir $backupdir/$curdate
    chmod 777 $backupdir/$curdate
fi
cd $backupdir/$curdate

# create and upload mysql bases backup
if [ $mysql = YES ]; then
    echo "Begin export databases"
    for base in $backupsqlbases
	do
	$mysqlutilspath'mysqldump' $sqldef --user=$sqluser --password=$sqlpass --host=$sqlhost $base > $backupdir/$curdate/$base.sql
    done
    
    echo "Begin compress databases"
    nice -n 15 tar -cz -f $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz $backupdir/$curdate/*.sql
    rm $backupdir/$curdate/*.sql
    
    # get filesize
    if [ $checkos = "1" ]; then
	sqlbackupfilesize=`stat -f %z $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz`
	else
	sqlbackupfilesize=`stat -c %s $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz`
    fi
    
    if [ $encryptbackup = YES ]; then
	echo "Begin encrypt databases archive"
	
	echo "$encryptkey" | $gpgpath/gpg --no-tty --passphrase-fd 0 --cipher-algo AES256  -cq $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz
	rm $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz
	
	# get filesize for gpg files
        if [ $checkos = "1" ]; then
            sqlbackupfilesizegpg=`stat -f %z $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz$gpgext`
            else
            sqlbackupfilesizegpg=`stat -c %s $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz$gpgext`
        fi
    fi    
    
    if [ $uploadbackup = YES ]; then
	echo "Begin upload databases archive"
	ftp -i -n $ftphost 2>&1 1>>$scriptdir/ftpdump.txt <<END_SCRIPT
	quote USER $ftpuser
	quote PASS $ftppass
	binary
	put $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz$gpgext $curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz$gpgext
	quit
END_SCRIPT
    fi
    
    if [ $savelocalbackup = NO ]; then
	echo "Remove local copy databases archive"
	rm $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz
	rm $backupdir/$curdate/$hostn-sql-backup-$curdatewithhours-$salt.tar.gz$gpgext
    fi
fi

# create and upload file backup
if [ $filebackup = YES ]; then
    echo "Begin compress files archive"
    
    nice -n 15 tar -cz $newerparam -f $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz -T $incfile -X $exfile

    # get filesize
    if [ $checkos = "1" ]; then
        filebackupfilesize=`stat -f %z $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz`
        else
        filebackupfilesize=`stat -c %s $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz`
    fi
    
    if [ $encryptbackup = YES ]; then
	echo "Begin encrypt files archive"
	
        echo "$encryptkey" | $gpgpath/gpg --no-tty --passphrase-fd 0 --cipher-algo AES256  -cq $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz
        rm $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz
        
        # get filesize for gpg files
        if [ $checkos = "1" ]; then
            filebackupfilesizegpg=`stat -f %z $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz$gpgext`
            else
            filebackupfilesizegpg=`stat -c %s $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz$gpgext`
        fi
    fi
    
    if [ $uploadbackup = YES ]; then
	echo "Begin upload files archive"
	ftp -i -n $ftphost 2>&1 1>>$scriptdir/ftpdump.txt <<END_SCRIPT
	quote USER $ftpuser
	quote PASS $ftppass
	binary
	put $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz$gpgext $curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz$gpgext
	quit
END_SCRIPT
    fi
    
    if [ $savelocalbackup = NO ]; then
	echo "Begin remove local copy files archive"
        rm $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz
        rm $backupdir/$curdate/$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz$gpgext
    fi
fi


# update special file for incremental backup
touch $scriptdir/metka

backupenddate=`date "+%Y-%m-%d %H:%M %Z%n"`

# send result e-mail
if [ -f $backupdir/report ];  then
    rm $backupdir/report
fi

if [ $emailresult = YES ]; then
    echo "Send a e-mail with the results"

    echo "Subject: $hostn `date "+%Y-%m-%d%n"` backup result" >> $backupdir/report
    
    echo "Backup started: $backupstartdate
Backup ended: $backupenddate" >> $backupdir/report
    
    echo "After backup free space on "$backupdir" - "`df -m $backupdir | grep dev | awk '{print $4}'`" MB" >> $backupdir/report  
    
    if [ $filebackup = YES ]; then
	echo "Current file backup - "$filebackupfilesize" bytes - "$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz >> $backupdir/report
	
	if [ $encryptbackup = YES ]; then
	    echo "Current encrypted file backup - "$filebackupfilesizegpg" bytes - "$hostn-$backuptype-file-backup-$curdatewithhours-$salt.tar.gz$gpgext >> $backupdir/report
	fi
    fi

    if [ $mysql = YES ]; then
	echo "Current mysql backup - "$sqlbackupfilesize" bytes - "$hostn-sql-backup-$curdatewithhours-$salt.tar.gz >> $backupdir/report
	
	if [ $encryptbackup = YES ]; then
	    echo "Current encrypted mysql backup - "$sqlbackupfilesizegpg" bytes - "$hostn-sql-backup-$curdatewithhours-$salt.tar.gz$gpgext >> $backupdir/report
	fi
    fi
    
    if [ $uploadbackup = YES ]; then
	echo "Error during ftp upload: " >> $backupdir/report
	cat $scriptdir"/ftpdump.txt" >> $backupdir/report
    fi

    echo "
Local backup folder statistics:" >> $backupdir/report
    if [ $checkos = "1" ]; then
	du -hc -d 1 $backupdir >> $backupdir/report
	else
	du -hc --max-depth=1 $backupdir >> $backupdir/report
    fi

    cat $backupdir/report | $sendmailpath"/sendmail" $emailforresult
    rm $backupdir/report
fi

echo "Backup complete"
exit
