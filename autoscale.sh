#!/bin/bash
set -v

# find ami id
AMI_ID_OLD=`ssh chetanm@52.86.207.63 cat /etc/haproxy/config.php  | grep "ami-" | awk -F"\"" '{print $2}'`
echo AMI old id is $AMI_ID_OLD

# find old instances and run query log script
for i in `aws ec2 describe-instances --filters "Name=image-id,Values=ami-4c5e2c5b" "Name=instance-state-name,Values=running" --query Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress --output text`
do
ssh -p 22456 chetanm@$i -t 'sudo /root/scripts/querylog.sh'
done


# find instance id
INSTANCE_ID_OLD=`aws ec2 describe-instances --filters "Name=image-id,Values=$AMI_ID_OLD" "Name=instance-state-name,Values=running" --query Reservations[0].Instances[].InstanceId --output text`
echo Old instance id is $INSTANCE_ID_OLD

# Run

# Set new Instance ID name
INSTANCE_NAME=JBL-Prod-Web-API-Autoscaled-`date +%d%m%Y%H%M`
echo Instance name is $INSTANCE_NAME

# Take AMI
echo Starting take $INSTANCE_ID_OLD instance ami
aws ec2 create-image --instance-id $INSTANCE_ID_OLD --name $INSTANCE_NAME --description $INSTANCE_NAME --no-reboot

# Find new AMI_ID_NEW
sleep 60
AMI_ID_NEW=`aws ec2 describe-images --owners 323051035076 --filters "Name=description,Values=$INSTANCE_NAME" --query Images[*].ImageId --output text`
while [ -z $AMI_ID_NEW ]; do
echo not find ami id
sleep 10
AMI_ID_NEW=`aws ec2 describe-images --owners 323051035076 --filters "Name=description,Values=$INSTANCE_NAME" --query Images[*].ImageId --output text`
done
echo exit loop
echo new AMI ID is $AMI_ID_NEW

# check ami status
STATE=`aws ec2 describe-images --owners 323051035076  --image-ids $AMI_ID_NEW --output text --query Images[].State`
echo $STATE
while [ "$STATE" != "available" ]; do
echo $STATE
sleep 10
STATE=`aws ec2 describe-images --owners 323051035076  --image-ids $AMI_ID_NEW --output text --query Images[].State`
done
echo $INSTANCE_ID_OLD instance ami  is ready $AMI_ID_NEW

# Tag AMI
echo start to tag $INSTANCE_NAME
aws ec2 create-tags --resources $AMI_ID_NEW --tags Key=Name,Value=$INSTANCE_NAME
echo Tagging for $INSTANCE_NAME is done

#Create new launch configuration
LCN=JBL-Prod-Web-API-Autoscaled-`date +%d%m%Y%H%M`
echo starting to create launch configuration $LCN
aws autoscaling create-launch-configuration --launch-configuration-name $LCN --key-name Devopstech-JBL --image-id $AMI_ID_NEW --security-groups sg-47153e3f --instance-type c4.xlarge --instance-monitoring Enabled=false --no-ebs-optimized --no-associate-public-ip-address
echo launch configuration created

# Increase instance size in existing launch configuration
ASCN=DevOpsTech-API-autoscale
echo attach $LCN to $ASCN
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASCN --launch-configuration-name $LCN --min-size 4 --desired-capacity 4 --max-size 12

# check server status
echo new ami id is $AMI_ID_NEW
sleep 60
c=`aws ec2 describe-instances --filters "Name=image-id,Values=${AMI_ID_NEW}" "Name=instance-state-name,Values=running" --output text --query Reservations[].Instances[].InstanceId `
echo Newly added instance id $c
for ia in `aws ec2 describe-instances --filters "Name=image-id,Values=$AMI_ID_NEW" "Name=instance-state-name,Values=running" --output text --query Reservations[].Instances[].InstanceId `;do
	echo instance id is $ia
     OP=`aws ec2 describe-instance-status --instance-ids $ia --query InstanceStatuses[].InstanceStatus[].Status --output text`
	echo $ia instance status is $OP
     while [ "$OP" != "ok" ] ; do
        sleep 10
        echo not up
         OP=`aws ec2 describe-instance-status --instance-ids $ia --query InstanceStatuses[].InstanceStatus[].Status --output text`
	echo $ia instance status is $OP
     done
done

#modify config.php
echo modifying config.php
ssh -t chetanm@52.86.207.63 sudo sed -i 's/'$AMI_ID_OLD'/'$AMI_ID_NEW'/g' /etc/haproxy/config.php ; ssh -t chetanm@52.86.207.63 sudo /usr/bin/php /etc/haproxy/config.php
echo sleep for 120 sec
sleep 120

# Check servers are added or not
NEW_IP=`ssh  chetanm@52.86.207.63 tail -1 /etc/haproxy/haproxy.cfg  | grep api | awk {'print $3'} | awk -F":" {'print $1'}`
echo api ip on haproxy.cfg is $NEW_IP
for IP in `aws ec2 describe-instances --filters "Name=image-id,Values=$AMI_ID_NEW" --output text --query Reservations[].Instances[].PrivateIpAddress `;do
echo $NEW_IP compare with $IP
if [ $IP == $NEW_IP ] ;
then
    echo IP not matched
# Decrease instance size in existing launch configuration
    echo start to decrease count in autoscaling group
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASCN --launch-configuration-name $LCN --min-size 2 --desired-capacity 2 --max-size 12
    echo changes done
else
    echo IP not matched
fi
done
set +v