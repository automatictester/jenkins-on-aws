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

packer build \
    -var "jenkins_home_volume_id=${JENKINS_HOME_VOLUME_ID}" \
    -var "jenkins_vpc_id=${JENKINS_VPC_ID}" \
    -var "jenkins_subnet_id=${JENKINS_SUBNET_ID}" \
    ../packer/jenkins-master.json
