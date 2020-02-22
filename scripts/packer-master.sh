#!/usr/bin/env bash

EFS_FILESYSTEM_ID=$(aws efs describe-file-systems \
    --query 'FileSystems[?Name == `Jenkins Home`].FileSystemId' \
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

JENKINS_MASTER_SG_ID=$(aws ec2 describe-security-groups \
    --filters 'Name=tag:Name,Values=Jenkins Master' \
    --query 'SecurityGroups[0].GroupId' \
    --output text
)

JENKINS_FARM_SG_ID=$(aws ec2 describe-security-groups \
    --filters 'Name=tag:Name,Values=Jenkins Farm' \
    --query 'SecurityGroups[0].GroupId' \
    --output text
)

packer build \
    -var "efs_filesystem_id=${EFS_FILESYSTEM_ID}" \
    -var "jenkins_vpc_id=${JENKINS_VPC_ID}" \
    -var "jenkins_subnet_id=${JENKINS_SUBNET_ID}" \
    -var "jenkins_master_sg_id=${JENKINS_MASTER_SG_ID}" \
    -var "jenkins_farm_sg_id=${JENKINS_FARM_SG_ID}" \
    ../packer/jenkins-master.json
