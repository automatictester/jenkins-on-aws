#!/usr/bin/env bash

aws ec2 create-volume \
    --availability-zone eu-west-2a \
    --size 8 \
    --volume-type gp2 \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=JENKINS_HOME}]'
