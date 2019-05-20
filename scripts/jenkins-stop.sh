#!/usr/bin/env bash

JENKINS_MASTER_INSTANCE_ID=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=Jenkins Master' 'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].InstanceId' --output text)
echo "Jenkins Master instance ID: ${JENKINS_MASTER_INSTANCE_ID}"

echo -n 'Stopping Jenkins Master... '
aws ec2 stop-instances --instance-ids ${JENKINS_MASTER_INSTANCE_ID} --output text >> /dev/null
echo 'done!'

JENKINS_SLAVE_INSTANCE_ID=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=jenkins slave - t3.medium' 'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].InstanceId' --output text)
echo "Jenkins Slave instance ID: ${JENKINS_SLAVE_INSTANCE_ID}"

echo -n 'Terminating Jenkins Slave, if any... '
aws ec2 terminate-instances --instance-ids ${JENKINS_SLAVE_INSTANCE_ID} --output text &> /dev/null
echo 'done!'

echo -n 'Wait for Jenkins Master to stop... '
aws ec2 wait instance-stopped --instance-ids ${JENKINS_MASTER_INSTANCE_ID}
echo 'done!'
