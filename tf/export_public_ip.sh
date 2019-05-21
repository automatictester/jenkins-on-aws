#!/usr/bin/env bash

export TF_VAR_public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo "Public IP: ${TF_VAR_public_ip}"
