#!/usr/bin/env bash

JENKINS_HOME_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters 'Name=tag:Name,Values=JENKINS_HOME' \
    --query 'Volumes[0].VolumeId' \
    --output text
)

JENKINS_VPC_ID=$(aws ec2 describe-vpcs \
    --filters 'Name=tag:Name,Values=Jenkins VPC' \
    --query 'Vpcs[0].VpcId' \
    --output text
)

JENKINS_SUBNET_ID=$(aws ec2 describe-subnets \
    --filters 'Name=tag:Name,Values=Jenkins Subnet' \
    --query 'Subnets[0].SubnetId' \
    --output text
)

JENKINS_MASTER_AMI_ID=$(aws ec2 describe-images \
    --filters Name=tag:Name,Values='Jenkins Master' \
    --query 'Images[0].ImageId' \
    --output text
)

JENKINS_MASTER_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters 'Name=tag:Name,Values=Jenkins Master' 'Name=instance-state-name,Values=stopped' \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text
)

echo "JENKINS_HOME Volume ID: ${JENKINS_HOME_VOLUME_ID}"
echo "Jenkins VPC ID: ${JENKINS_VPC_ID}"
echo "Jenkins Subnet ID: ${JENKINS_SUBNET_ID}"
echo "Old Jenkins Master AMI ID: ${JENKINS_MASTER_AMI_ID}"
echo "Old Jenkins Master Instance ID: ${JENKINS_MASTER_INSTANCE_ID}"

echo -n "Renaming AMI 'Jenkins Master' to 'OLD Jenkins Master'... "
aws ec2 create-tags --resources ${JENKINS_MASTER_AMI_ID} --tags Key=Name,Value='OLD Jenkins Master'
echo "done!"

echo -n "Renaming instance 'Jenkins Master' to 'OLD Jenkins Master'... "
aws ec2 create-tags --resources ${JENKINS_MASTER_INSTANCE_ID} --tags Key=Name,Value='OLD Jenkins Master'
echo "done!"

packer build \
    -var "jenkins_home_volume_id=${JENKINS_HOME_VOLUME_ID}" \
    -var "jenkins_vpc_id=${JENKINS_VPC_ID}" \
    -var "jenkins_subnet_id=${JENKINS_SUBNET_ID}" \
    ../packer/jenkins-master.json
