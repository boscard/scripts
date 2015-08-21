#!/bin/bash

set -xe

wordpressDir="$2"
wordpressVersion="$1"
wordpressUrl="https://pl.wordpress.org/"
wordpressLang="pl_PL"
tmp="/var/backupTmp/wordpressTmp"
bckpDir="/var/backupTmp/wordpressBckp"
toDelete="wp-includes wp-admin"

test -z "$wordpressDir" -o -z "$wordpressVersion" && echo "Usage: $0 <wordpressVersion> <wordpressDir>" >&2 && exit 1
test -e "$tmp" && echo "Temporary path '$tmp' already exists." >&2 && exit 1
test -e "$bckpDir" || mkdir -p "$bckpDir"

# Create tmp dirs
mkdir -p $tmp

# Download update
test -e "$bckpDir/wordpress-$wordpressVersion-$wordpressLang.tar.gz" || wget "$wordpressUrl/wordpress-$wordpressVersion-$wordpressLang.tar.gz" -O "$bckpDir/wordpress-$wordpressVersion-$wordpressLang.tar.gz"

# create backup
fileDate=`date +"%Y%m%d%H%M"`
tar -czf "$bckpDir/wp.code.$fileDate.tgz" $wordpressDir
dbName=`grep -i DB_NAME $wordpressDir/wp-config.php  | awk '{ print $2 }' |  sed -e "s/'//g" -e 's/);//g'`
dbUserName=`grep -i DB_USER $wordpressDir/wp-config.php  | awk '{ print $2 }' |  sed -e "s/'//g" -e 's/);//g'`
dbPassword=`grep -i DB_PASSWORD $wordpressDir/wp-config.php  | awk '{ print $2 }' |  sed -e "s/'//g" -e 's/);//g'`
dbHost=`grep -i DB_HOST $wordpressDir/wp-config.php  | awk '{ print $2 }' |  sed -e "s/'//g" -e 's/);//g'`

mysqldump -u$dbUserName -p$dbPassword -h$dbHost $dbName > $bckpDir/wp.db.$fileDate.sql

# Update

# unpack archive 
tar -xzf "$bckpDir/wordpress-$wordpressVersion-$wordpressLang.tar.gz" -C $tmp
chown -R apache:apache $tmp

for deleteData in $toDelete
do
	rm -rf $wordpressDir/$deleteData
done

cp -R $tmp/wordpress/* $wordpressDir

chcon -t httpd_sys_content_t -R $wordpressDir

# Cleanup
rm -rf $tmp
