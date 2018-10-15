## This script sync previous day's scalar logs to s3 bucket name jbl-scalearc-logs and also keeps only last 7 days worth of logs on local server

#!/bin/bash
set -v
mkdir -p /root/logs-report_scalarc-log_sync

rm -rf /root/logs-report_scalarc-log_sync/*

 
AWSCLI=/usr/bin/aws
path=`date +%Y%m%d --date="1 days ago"`
cd /home/saloguser
# $AWSCLI s3 sync $path s3://jbl-scalearc-logs/$path/

echo "Starting Sync" > /root/logs-report_scalarc-log_sync/report_scalarc-log_sync.txt
$AWSCLI s3 sync /home/saloguser/ s3://jbl-scalearc-logs-nv/ >>  /root/logs-report_scalarc-log_sync/report_scalarc-log_sync.txt
sleep 10

echo  "## now cleaning logs older than 7 days"
echo ' '


mkdir -p /root/old_saloguser/

#find /home/saloguser/ -maxdepth 1 -mtime +7 -type d -exec mv "{}" /root/old_saloguser/ \;  >>  /root/logs-report_scalarc-log_sync/report_scalarc-log_sync.txt
find /home/saloguser/* -maxdepth 1 -mtime +7 -type d -exec mv "{}" /root/old_saloguser/ \;  >>  /root/logs-report_scalarc-log_sync/report_scalarc-log_sync.txt


#rm -rf /root/old_saloguser/*

(echo -e "From: scalearc-log-cleanup@justbuylive.com  \nTo: krunal@justbuylive.com \nMIME-Version: 1.0 \nSubject: Scalearc Log Purge `date` \nContent-Type: text/html \n"; cat /root/logs-report_scalarc-log_sync/report_scalarc-log_sync.txt ) | /usr/sbin/sendmail -t
