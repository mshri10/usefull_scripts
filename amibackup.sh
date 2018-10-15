#!/bin/bash

REGION=us-east-1
cd /root/aws_scripts_jblsysadmin/

echo "AMI Image Creation" > FINRESULT.log

echo "<br>" >>  FINRESULT.log

echo "<table border=5 align="center">" >> FINRESULT.log

echo "<tr>" >> FINRESULT.log

echo "<th>Server</th>" >> FINRESULT.log

echo "<th>Action</th>" >> FINRESULT.log

echo "</tr>" >> FINRESULT.log

echo "<br>" >> AMI_RESULT.log

echo "Status of AMI backup of Servers under JBL Account" >> AMI_RESULT.log

echo "<br>" >> AMI_RESULT.log

echo "<table border=5 align="center">" >> AMI_RESULT.log

echo "<tr>" >> AMI_RESULT.log

echo "<th> Region </th>" >>  AMI_RESULT.log

echo "<th> "Server Name" </th>" >> AMI_RESULT.log

echo "<th> "Instance ID" </th>" >> AMI_RESULT.log

echo "<th> "AMI Name"  </th>" >> AMI_RESULT.log

echo "<th> "Corresponding AMI ID"  </th>" >> AMI_RESULT.log

#echo "<th> "Coresponding Snapshot of AMI"  </th>" >> AMI_RESULT.log

echo "</tr>" >> AMI_RESULT.log



#aws ec2 describe-regions --region us-east-1 --output text | awk '{print $3}'  > region.txt

cp /root/aws_scripts_jblsysadmin/db_server_list.lst  /root/aws_scripts_jblsysadmin/serverlist.txt

# aws ec2 describe-instances --region ap-northeast-1 --profile default --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].[Value],[InstanceId]]' --output text | awk 'NR%2{printf $0" ";next;}1' > serverlist.txt



           if [ -s "serverlist.txt" ];

           then

               for SERVERS in $(cat serverlist.txt | awk '{print $1}')

               do


                  INSTANCE_ID=`cat serverlist.txt | grep $SERVERS | awk '{print $2}'`

                  echo $INSTANCE_ID



                CUR_DATE=`date '+%d%m%y'`

                echo $CUR_DATE

                  CHECK_IMAGE_EXISTANCE=$(aws ec2 describe-images --region $REGION --profile default --filter "Name=name,Values=$SERVERS-img_$CUR_DATE" --query "Images[].[Name]" --output text)

                if [ -z "$CHECK_IMAGE_EXISTANCE" ];

                        then

                               CREATE_IMAGE=`aws ec2 create-image --instance-id $INSTANCE_ID --profile default --name "$SERVERS-img_$CUR_DATE" --no-reboot --region $REGION 2> err.txt`

                          sleep 40

                                  if [ -s "err.txt" ];

                                  then

                                      echo "<TR>" >> FINRESULT.log

                                      echo "<TD>$SERVERS</TD>" >> FINRESULT.log

                                      echo "<TD><PRE> `cat err.txt` </PRE></TD>" >> FINRESULT.log

                                      echo "</TR>" >> FINRESULT.log

                                   else

                                      echo "<TR>" >> FINRESULT.log

                                      echo "<TD>$SERVERS</TD>" >> FINRESULT.log

                                      echo "<TD>AMI Image Creation: Success</TD>" >> FINRESULT.log

                                      echo "</TR>" >> FINRESULT.log

                                   fi

                else

                                echo "<TR>" >> FINRESULT.log

                                      echo "<TD>$SERVERS</TD>" >> FINRESULT.log

                                      echo "<TD><PRE>AMI Already exists of $CUR_DATE</PRE></TD>" >> FINRESULT.log

                                      echo "</TR>" >> FINRESULT.log

                fi
done


fi

####


aws ec2 describe-images --region $REGION --profile default --filter "Name=name,Values=$SERVERS*" --query "Images[].[Name]" --output text > available_ami.txt

                                   echo "<tr>" >> AMI_RESULT.log

             echo "<td> ap-northeast-1 </td>" >> AMI_RESULT.log

             echo "<td> $SERVERS </td>" >> AMI_RESULT.log

             echo "<td> $INSTANCE_ID </td>" >> AMI_RESULT.log

             echo "<td><PRE> `cat available_ami.txt` </PRE></td>" >> AMI_RESULT.log

#              echo "<td><pre> `cat total_ami.txt` </td>" >> AMI_RESULT.log
#
#             echo "<td><pre> `cat total_snap.txt` </td>" >> AMI_RESULT.log

             echo "</tr>" >> AMI_RESULT.log

######





echo "</TABLE>" >> FINRESULT.log

echo "</TABLE>" >> AMI_RESULT.log

cat AMI_RESULT.log >> FINRESULT.log


#aws ec2 describe-images --region $REGION --profile default --filter "Name=name,Values=$SERVERS-img*" --query "Images[].[Name,ImageId]" --output text  | awk '{ print $2}' > AMI_FILE.txt


(echo -e "From: ami@justbuylive.com \nTo: krunal.shah@justbuylive.com, aadinath.rakshe@justbuylive.com \nMIME-Version: 1.0 \nSubject:Server AMI Backup status in Amazon JBLAWS Account \nContent-Type: text/html \n"; cat FINRESULT.log) | /usr/sbin/sendmail -t


  rm -rf *.txt *.log

