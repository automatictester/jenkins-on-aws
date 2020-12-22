#!/usr/bin/env bash

validate_context() {
  CONFIG_FILE='vars.sh'
  if [ -f "${CONFIG_FILE}" ]; then

    source "${CONFIG_FILE}"

    if [ -z "${JENKINS_MASTER_DOMAIN_NAME}" ]; then
      echo 'JENKINS_MASTER_DOMAIN_NAME not set, exiting'
      exit 1
    fi

    if [ -z "${HOSTED_ZONE_ID}" ]; then
      echo 'HOSTED_ZONE_ID not set, exiting'
      exit 1
    fi

  else
    echo "File '${CONFIG_FILE}' does not exist, exiting"
    exit 1
  fi

  OS=$(uname)
  if [ "${OS}" != 'Darwin' ]; then
    echo 'This script is for macOS only, exiting'
    exit 1
  fi
}

read_state() {
  JENKINS_MASTER_INSTANCE_ID=$(
    aws ec2 describe-instances \
      --filters 'Name=tag:Name,Values=Jenkins Master' 'Name=instance-state-name,Values=running' \
      --output text --query 'Reservations[*].Instances[*].InstanceId'
  )

  if [ -z "${JENKINS_MASTER_INSTANCE_ID}" ]; then
    echo 'Jenkins Master instance not found'
    exit 1
  else
    echo "Jenkins Master instance ID: ${JENKINS_MASTER_INSTANCE_ID}"
  fi

  JENKINS_MASTER_PUBLIC_IP=$(
    aws ec2 describe-instances \
      --filters 'Name=tag:Name,Values=Jenkins Master' \
      --output text \
      --query 'Reservations[*].Instances[*].PublicIpAddress'
  )

  if [ -z "${JENKINS_MASTER_PUBLIC_IP}" ]; then
    echo 'Jenkins Master public IP address not found'
    exit 1
  fi
}

stop_jenkins() {
  echo 'Stopping Jenkins Master... '
  aws ec2 stop-instances \
    --instance-ids "${JENKINS_MASTER_INSTANCE_ID}" \
    --output text >>/dev/null
  echo 'Done!'
}

maybe_stop_jenkins_slave() {
  JENKINS_SLAVE_INSTANCE_ID=$(
    aws ec2 describe-instances \
      --filters 'Name=tag:Name,Values=jenkins slave - t3.medium' 'Name=instance-state-name,Values=running' \
      --query 'Reservations[*].Instances[*].InstanceId' \
      --output text
  )

  if [ -z "${JENKINS_SLAVE_INSTANCE_ID}" ]; then
    echo 'Jenkins Slave instance not found'
  else
    echo "Jenkins Slave instance ID: ${JENKINS_SLAVE_INSTANCE_ID}"
    echo 'Terminating Jenkins Slave... '
    aws ec2 terminate-instances --instance-ids "${JENKINS_SLAVE_INSTANCE_ID}" --output text &>/dev/null
    echo 'Done!'
  fi
}

wait_for_instance_to_stop() {
  echo 'Wait for Jenkins Master to stop... '
  aws ec2 wait instance-stopped --instance-ids "${JENKINS_MASTER_INSTANCE_ID}"
  echo 'Done!'
}

delete_dns() {
  echo 'Deleting DNS record... '
  aws route53 change-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --change-batch "{ \"Changes\": [ { \"Action\": \"DELETE\", \"ResourceRecordSet\": { \"Name\": \"${JENKINS_MASTER_DOMAIN_NAME}\", \"Type\": \"A\", \"TTL\": 60, \"ResourceRecords\": [ { \"Value\": \"${JENKINS_MASTER_PUBLIC_IP}\" } ] } } ] }" >>/dev/null
  echo 'Done!'
}

validate_context
read_state
delete_dns
stop_jenkins
maybe_stop_jenkins_slave
wait_for_instance_to_stop
