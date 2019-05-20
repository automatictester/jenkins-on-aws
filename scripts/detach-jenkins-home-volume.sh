#!/usr/bin/env bash

JENKINS_HOME_VOLUME_ID=$(aws ec2 describe-volumes \
    --query 'Volumes[*].Attachments[?Device==`/dev/xvdf`].VolumeId' \
    --output text
)

echo "Detaching volume..."

aws ec2 detach-volume --volume-id ${JENKINS_HOME_VOLUME_ID}
aws ec2 wait volume-available --volume-ids ${JENKINS_HOME_VOLUME_ID}

echo "Volume detached"
