#!/usr/bin/env bash

JENKINS_HOME_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters 'Name=tag:Name,Values=JENKINS_HOME' \
    --output text \
    --query 'Volumes[0].VolumeId'
)

packer build -var "jenkins_home_volume_id=${JENKINS_HOME_VOLUME_ID}" ../packer/jenkins-master.json
