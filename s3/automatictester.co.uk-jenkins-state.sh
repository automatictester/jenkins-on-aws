#!/usr/bin/env bash

aws s3api create-bucket \
   --bucket automatictester.co.uk-jenkins-state \
   --acl private \
   --region eu-west-2 \
   --create-bucket-configuration LocationConstraint=eu-west-2

aws s3api put-public-access-block \
   --bucket automatictester.co.uk-jenkins-state \
   --public-access-block-configuration '{"BlockPublicAcls":true,"IgnorePublicAcls":true,"BlockPublicPolicy":true,"RestrictPublicBuckets":true}'
