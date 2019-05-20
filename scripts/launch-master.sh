#!/usr/bin/env bash

JENKINS_MASTER_AMI_ID=$(aws ec2 describe-images \
    --filters Name=tag:Name,Values='Jenkins Master' \
    --query 'Images[0].ImageId' \
    --output text
)

JENKINS_HOME_SNAPSHOT_ID=$(aws ec2 describe-images \
    --filters Name=tag:Name,Values='Jenkins Master' \
    --query 'Images[0].BlockDeviceMappings[?DeviceName==`/dev/xvdf`].Ebs.SnapshotId' \
    --output text
)

JENKINS_SUBNET_ID=$(aws ec2 describe-subnets \
    --filters Name=tag:Name,Values='Jenkins Subnet' \
    --query 'Subnets[0].SubnetId' \
    --output text
)

JENKINS_FARM_SG_ID=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values='Jenkins Farm' \
    --query 'SecurityGroups[0].GroupId' \
    --output text
)

JENKINS_MASTER_SG_ID=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values='Jenkins Master' \
    --query 'SecurityGroups[0].GroupId' \
    --output text
)

JENKINS_HOME_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters 'Name=tag:Name,Values=JENKINS_HOME' \
    --query 'Volumes[0].VolumeId' \
    --output text
)

JENKINS_MASTER_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters 'Name=tag:Name,Values=Jenkins Master' \
    --query 'Volumes[0].VolumeId' \
    --output text
)

echo "Jenkins Master AMI ID: ${JENKINS_MASTER_AMI_ID}"
echo "Jenkins Subnet ID: ${JENKINS_SUBNET_ID}"
echo "Jenkins Farm Security Group ID: ${JENKINS_FARM_SG_ID}"
echo "Jenkins Master Security Group ID: ${JENKINS_MASTER_SG_ID}"
echo "JENKINS_HOME Snapshot ID: ${JENKINS_HOME_SNAPSHOT_ID}"
echo "JENKINS_HOME Volume ID: ${JENKINS_HOME_VOLUME_ID}"
echo "Jenkins Master Volume ID: ${JENKINS_MASTER_VOLUME_ID}"

echo -n "Renaming volume 'JENKINS_HOME' to 'OLD JENKINS_HOME'... "
aws ec2 create-tags --resources ${JENKINS_HOME_VOLUME_ID} --tags Key=Name,Value='OLD JENKINS_HOME'
echo "done!"

echo -n "Renaming volume 'Jenkins Master' to 'OLD Jenkins Master'... "
aws ec2 create-tags --resources ${JENKINS_MASTER_VOLUME_ID} --tags Key=Name,Value='OLD Jenkins Master'
echo "done!"

aws ec2 run-instances \
    --count 1 \
    --image-id ${JENKINS_MASTER_AMI_ID} \
    --instance-type t2.micro \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\",\"VolumeSize\":8}},{\"DeviceName\":\"/dev/xvdf\",\"Ebs\":{\"DeleteOnTermination\":false,\"VolumeType\":\"gp2\",\"VolumeSize\":8,\"SnapshotId\":\"${JENKINS_HOME_SNAPSHOT_ID}\"}}]" \
    --subnet-id ${JENKINS_SUBNET_ID} \
    --security-group-ids ${JENKINS_FARM_SG_ID} ${JENKINS_MASTER_SG_ID} \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Jenkins Master}]' \
    --iam-instance-profile Name=Jenkins \
    --instance-initiated-shutdown-behavior stop \
    --key-name id_rsa_jenkins_gmail_np

JENKINS_MASTER_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters 'Name=tag:Name,Values=Jenkins Master' 'Name=instance-state-name,Values=pending' \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text
)

echo "Jenkins Master instance ID: ${JENKINS_MASTER_INSTANCE_ID}"

echo -n 'Wait for Jenkins master to start... '
aws ec2 wait instance-running --instance-ids ${JENKINS_MASTER_INSTANCE_ID}
echo 'done!'

JENKINS_MASTER_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters Name=attachment.instance-id,Values=${JENKINS_MASTER_INSTANCE_ID} Name=attachment.device,Values=/dev/sda1 \
    --query 'Volumes[0].Attachments[0].VolumeId' \
    --output text
)

JENKINS_HOME_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters Name=attachment.instance-id,Values=${JENKINS_MASTER_INSTANCE_ID} Name=attachment.device,Values=/dev/xvdf \
    --query 'Volumes[0].Attachments[0].VolumeId' \
    --output text
)

echo -n "Tagging volume 'Jenkins Master'... "
aws ec2 create-tags --resources ${JENKINS_MASTER_VOLUME_ID} --tags Key=Name,Value='Jenkins Master'
echo "done!"

echo -n "Tagging volume 'JENKINS_HOME'... "
aws ec2 create-tags --resources ${JENKINS_HOME_VOLUME_ID} --tags Key=Name,Value='JENKINS_HOME'
echo "done!"
