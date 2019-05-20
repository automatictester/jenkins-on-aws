#!/usr/bin/env bash

# This script requires 'vars.sh' declaring JENKINS_MASTER_DOMAIN_NAME and HOSTED_ZONE_ID variables

PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo "Your public IP: ${PUBLIC_IP}"

JENKINS_MASTER_INSTANCE_ID=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=Jenkins Master' 'Name=instance-state-name,Values=stopped' --output text --query 'Reservations[*].Instances[*].InstanceId')
echo "Jenkins Master instance ID: ${JENKINS_MASTER_INSTANCE_ID}"

JENKINS_MASTER_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters 'Name=tag:Name,Values=Jenkins Master' --query 'SecurityGroups[*].GroupId' --output text)
echo "Jenkins Master security group ID: ${JENKINS_MASTER_SECURITY_GROUP_ID}"

echo -n 'Setting Jenkins Master security group to accept inbound connections only from your public IP... '
OLD_SSH_CIDR=$(aws ec2 describe-security-groups --filters "Name=description,Values=SSH and Jenkins HTTPS from my public IP only" --query 'SecurityGroups[*].IpPermissions[?FromPort==`22`].IpRanges[*].CidrIp' --output text)
aws ec2 revoke-security-group-ingress --group-id ${JENKINS_MASTER_SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr ${OLD_SSH_CIDR}
aws ec2 authorize-security-group-ingress --group-id ${JENKINS_MASTER_SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr "${PUBLIC_IP}/32"

OLD_HTTPS_CIDR=$(aws ec2 describe-security-groups --filters "Name=description,Values=SSH and Jenkins HTTPS from my public IP only" --query 'SecurityGroups[*].IpPermissions[?FromPort==`443`].IpRanges[*].CidrIp' --output text)
aws ec2 revoke-security-group-ingress --group-id ${JENKINS_MASTER_SECURITY_GROUP_ID} --protocol tcp --port 443 --cidr ${OLD_HTTPS_CIDR}
aws ec2 authorize-security-group-ingress --group-id ${JENKINS_MASTER_SECURITY_GROUP_ID} --protocol tcp --port 443 --cidr "${PUBLIC_IP}/32"
echo 'done!'

echo -n 'Starting Jenkins Master... '
aws ec2 start-instances --instance-ids ${JENKINS_MASTER_INSTANCE_ID} --output text >> /dev/null
echo 'done!'

echo -n 'Updating DNS record... '
source vars.sh
JENKINS_MASTER_PUBLIC_IP=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=Jenkins Master' --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch "{ \"Changes\": [ { \"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${JENKINS_MASTER_DOMAIN_NAME}\", \"Type\": \"A\", \"TTL\": 60, \"ResourceRecords\": [ { \"Value\": \"${JENKINS_MASTER_PUBLIC_IP}\" } ] } } ] }" >> /dev/null
echo 'done!'

echo -n 'Removing stale entry from ~/.ssh/known_hosts file... '
TRANSFORMED_JENKINS_MASTER_DOMAIN_NAME=$(echo ${JENKINS_MASTER_DOMAIN_NAME} | sed 's/\.$//')
ssh-keygen -R ${TRANSFORMED_JENKINS_MASTER_DOMAIN_NAME} &> /dev/null
echo 'done!'

echo -n 'Flushing local DNS cache... '
sudo killall -HUP mDNSResponder
echo 'done!'

echo -n 'Wait for Jenkins Master to start... '
aws ec2 wait instance-running --instance-ids ${JENKINS_MASTER_INSTANCE_ID}
echo 'done!'