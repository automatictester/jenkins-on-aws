#!/usr/bin/env bash

JENKINS_HOME_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters 'Name=tag:Name,Values=JENKINS_HOME' \
    --output text \
    --query 'Volumes[0].VolumeId'
)

aws ec2 detach-volume --volume-id ${JENKINS_HOME_VOLUME_ID}
