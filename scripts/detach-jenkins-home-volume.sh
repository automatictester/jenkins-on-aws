#!/usr/bin/env bash

JENKINS_HOME_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters 'Name=tag:Name,Values=JENKINS_HOME' \
    --output text \
    --query 'Volumes[0].VolumeId'
)

echo "Detaching volume..."

aws ec2 detach-volume --volume-id ${JENKINS_HOME_VOLUME_ID}
aws ec2 wait volume-available --volume-ids ${JENKINS_HOME_VOLUME_ID}

echo "Volume detached"
