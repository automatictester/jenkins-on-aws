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
  PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
  echo "My public IP: ${PUBLIC_IP}"

  JENKINS_MASTER_INSTANCE_ID=$(
    aws ec2 describe-instances \
      --filters 'Name=tag:Name,Values=Jenkins Master' 'Name=instance-state-name,Values=stopped' \
      --output text --query 'Reservations[*].Instances[*].InstanceId'
  )

  if [ -z "${JENKINS_MASTER_INSTANCE_ID}" ]; then
    echo 'Jenkins Master instance not found'
    exit 1
  else
    echo "Jenkins Master instance ID: ${JENKINS_MASTER_INSTANCE_ID}"
  fi

  JENKINS_MASTER_SECURITY_GROUP_ID=$(
    aws ec2 describe-security-groups \
      --filters 'Name=tag:Name,Values=Jenkins Master' \
      --query 'SecurityGroups[*].GroupId' \
      --output text
  )

  if [ -z "${JENKINS_MASTER_SECURITY_GROUP_ID}" ]; then
    echo 'Jenkins Master security group not found'
    exit 1
  else
    echo "Jenkins Master security group ID: ${JENKINS_MASTER_SECURITY_GROUP_ID}"
  fi

  OLD_SSH_CIDR=$(
    aws ec2 describe-security-groups \
      --filters "Name=description,Values=SSH and HTTPS from my public IP only" \
      --query 'SecurityGroups[*].IpPermissions[?FromPort==`22`].IpRanges[*].CidrIp' \
      --output text
  )

  if [ -z "${OLD_SSH_CIDR}" ]; then
    echo 'Previous SSH ingress rule not found, exiting'
    exit 1
  fi

  OLD_HTTPS_CIDR=$(
    aws ec2 describe-security-groups \
      --filters "Name=description,Values=SSH and HTTPS from my public IP only" \
      --query 'SecurityGroups[*].IpPermissions[?FromPort==`443`].IpRanges[*].CidrIp' \
      --output text
  )

  if [ -z "${OLD_HTTPS_CIDR}" ]; then
    echo 'Previous HTTPS ingress rule not found, exiting'
    exit 1
  fi
}

update_security_group_rules() {
  echo 'Setting Jenkins Master security group to accept inbound connections only from my public IP... '
  aws ec2 revoke-security-group-ingress \
    --group-id "${JENKINS_MASTER_SECURITY_GROUP_ID}" \
    --protocol tcp \
    --port 22 \
    --cidr "${OLD_SSH_CIDR}" &>/dev/null

  aws ec2 authorize-security-group-ingress \
    --group-id "${JENKINS_MASTER_SECURITY_GROUP_ID}" \
    --protocol tcp \
    --port 22 \
    --cidr "${PUBLIC_IP}/32" &>/dev/null

  aws ec2 revoke-security-group-ingress \
    --group-id "${JENKINS_MASTER_SECURITY_GROUP_ID}" \
    --protocol tcp \
    --port 443 \
    --cidr "${OLD_HTTPS_CIDR}" &>/dev/null

  aws ec2 authorize-security-group-ingress \
    --group-id "${JENKINS_MASTER_SECURITY_GROUP_ID}" \
    --protocol tcp \
    --port 443 \
    --cidr "${PUBLIC_IP}/32" &>/dev/null
  echo 'Done!'
}

start_jenkins() {
  echo 'Starting Jenkins Master... '
  aws ec2 start-instances \
    --instance-ids "${JENKINS_MASTER_INSTANCE_ID}" \
    --output text >>/dev/null
  echo 'Done!'
}

update_dns() {
  echo 'Updating DNS record... '
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

  aws route53 change-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --change-batch "{ \"Changes\": [ { \"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${JENKINS_MASTER_DOMAIN_NAME}\", \"Type\": \"A\", \"TTL\": 60, \"ResourceRecords\": [ { \"Value\": \"${JENKINS_MASTER_PUBLIC_IP}\" } ] } } ] }" >>/dev/null
  echo 'Done!'
}

cleanup_known_hosts() {
  echo 'Removing stale entry from ~/.ssh/known_hosts file... '
  TRANSFORMED_JENKINS_MASTER_DOMAIN_NAME=$(echo "${JENKINS_MASTER_DOMAIN_NAME}" | sed 's/\.$//')
  ssh-keygen -R "${TRANSFORMED_JENKINS_MASTER_DOMAIN_NAME}" &>/dev/null
  echo 'Done!'
}

flush_dns_cache() {
  echo 'Flushing local DNS cache... '
  sudo killall -HUP mDNSResponder
  echo 'Done!'
}

wait_for_instance_to_start() {
  echo 'Wait for Jenkins Master to start... '
  aws ec2 wait instance-running --instance-ids "${JENKINS_MASTER_INSTANCE_ID}"
  echo 'Done!'
}

validate_context
read_state
update_security_group_rules
start_jenkins
update_dns
cleanup_known_hosts
flush_dns_cache
wait_for_instance_to_start
