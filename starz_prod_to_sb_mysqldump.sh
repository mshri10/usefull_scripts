#/bin/bash

#------------------------------------------------------------------------------------------------
# Description:
# Shell script to dump the mysql tables from Prod DW RDS to QA DW RDS
#--------------------------------------------------------------------------------------------------

# Exit this script when return code is non-zero
set -e

# debug mode Uncomment for verbose output.
#set -x

# Prod Database Credentials.Use Replica Endpoint as $prod_host
prod_user="user_db1"
prod_password=""
prod_host="endpoint.us-west-2.rds.amazonaws.com"
prod_db_name="DB_Name"

# QA Database Credentials
sb_user="root"
sb_password=""
sb_host="endpoint.us-west-2.rds.amazonaws.com"
sb_db_name="DB_name"

# Other Vars
date=$(date +"%d-%b-%Y")
mysqldump=$(which mysqldump)
mysql=$(which mysql)
backup_path="/mnt/data/dumps"

# Array of table names to dump from prod
prod_db_tables=(table1 table2 table3)

# Take Table Dump from Prod and import to SB
for i in "${prod_db_tables[@]}"
do
        echo -e '\nDumping Table to' $backup_path '------ Table ==> '$i
        $mysqldump -h $prod_host -u$prod_user -p$prod_password \
        $prod_db_name $i > $backup_path/$i$date.sql

        echo -e '\nImporting dumped SQL file to QA '$sb_host
        ls $backup_path/$i$date.sql
        $mysql -h $sb_host -u$sb_user -p$sb_password $sb_db_name < $backup_path/$i$date.sql
        echo -e '\nImported the table  to sandbox DB' $i
done


echo -e '\n-------------------------------------------------'
echo -e 'Prod to QA DB Tales copied succesfully'
echo -e 'NOTE: Files in the backup path '$backup_path ' will be retained for 10 days only'
echo '-------------------------------------------------'

# Data Retention 10 days. Delete dump backup files after 10 days
find $backup_path/* -mtime +10 -exec rm {} \;

