#!/bin/bash -xe
sudo apt-get install -y awscli
export AWS_DEFAULT_REGION=$(curl -sS http://169.254.169.254/latest/dynamic/instance-identity/document | python -c 'import sys, json; print(json.load(sys.stdin)[\"region\"])')
INSTANCE_ID=$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -sS http://169.254.169.254/latest/meta-data/placement/availability-zone) ho Availability Zone: ${AZ}
# ENI_ID=$(aws ec2 create-network-interface --subnet ${!SUBNET_ID} --description 'Secondary ENI' --groups ${SecurityGroups} --query 'NetworkInterface.NetworkInterfaceId' --output text)
#  {"SecurityGroups":  {"Fn::Join": [" ", {"Ref": "SecondaryNICSecurityGroupIds"}]}
# aws ec2 create-tags --resources ${!ENI_ID} --tags Key=Some,Value=Tag
# ATTACHMENT_ID=$(aws ec2 attach-network-interface --network-interface-id ${ENI_ID} --instance-id ${INSTANCE_ID} --device-index 1 --output text)
# echo Attachment ID: ${ATTACHMENT_ID}
# echo Delete On Termination: $(aws ec2 modify-network-interface-attribute --network-interface-id ${ENI_ID} --attachment AttachmentId=${ATTACHMENT_ID},DeleteOnTermination=true --output text


INSTANCE_ID=$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -sS http://169.254.169.254/latest/meta-data/placement/availability-zone)
result=$(aws ec2 describe-network-interfaces --region eu-west-1 --filters Name=availability-zone,Values=$AZ Name=tag:Name,Values=InternalBastionStaticENI --query "NetworkInterfaces[].[Status,NetworkInterfaceId,Attachment.AttachmentId]" --output text)
status=$(echo $result | awk '{print $1}')
eni_id=$(echo $result | awk '{print $2}')
attachment_id=$(echo $result | awk '{print $3}')
if [ "$status" != "available" ] ; then aws ec2 --region eu-west-1 detach-network-interface --attachment-id $attachment_id; sleep 30 ; fi
aws ec2 attach-network-interface --region eu-west-1 --device-index 1 --instance-id $INSTANCE_ID --network-interface-id $eni_id
