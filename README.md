# Jenkins on AWS

## Overview

Jenkins master and slaves on AWS EC2:
- Terraformed AWS infrastructure
- Packer AMI templates

Feel free to adapt and reuse.

## How-to

Shell scripts to create necessary S3 buckets (one-off):
- `./automatictester.co.uk-jenkins-state.sh`

Prepare AWS infrastructure (one-off):
- `terraform apply -auto-approve`

Build Jenkins Slave AMI:
- `./packer-slave.sh`

Build Jenkins Master AMI:
- `./packer-master.sh`
