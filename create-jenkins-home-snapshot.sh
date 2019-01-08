#!/usr/bin/env bash

JENKINS_HOME_VOLUME_ID=$(aws ec2 describe-volumes \
    --filters 'Name=tag:Name,Values=JENKINS_HOME' \
    --output text \
    --query 'Volumes[0].VolumeId'
)

DATE=$(date +"%Y-%m-%d")

echo "Creating snapshot..."

SNAPSHOT_ID=$(aws ec2 create-snapshot \
    --volume-id ${JENKINS_HOME_VOLUME_ID} \
    --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=JENKINS_HOME}]' \
    --description "BACKUP ${DATE}" \
    --output text \
    --query 'SnapshotId'
)

aws ec2 wait snapshot-completed --snapshot-ids ${SNAPSHOT_ID}

echo "Snapshot ready"
