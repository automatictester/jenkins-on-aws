# Jenkins on AWS

## Overview

Jenkins Master and Slave on AWS EC2:
- Packer AMI templates
- Terraformed AWS infrastructure
- Lifecycle management scripts

Feel free to adapt and reuse.

## How-to

Prepare AWS infrastructure (one-off):
- `export TF_VAR_public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)`
- `terraform apply -auto-approve`

Create empty JENKINS_HOME volume (one-off):
- `./create-empty-jenkins-home-volume.sh`

Build Jenkins Slave AMI:
- `./packer-slave.sh`

Build Jenkins Master AMI:
- `./detach-jenkins-home-volume.sh`
- `./packer-master.sh`

Launch new Jenkins Master:
- `./launch-master.sh`

Stop Jenkins Master (and Slave, if any):
- `./jenkins-stop.sh`

Start Jenkins Master:
- `./jenkins-start.sh`

Backup JENKINS_HOME:
- `./create-jenkins-home-snapshot.sh`

- Shell scripts to create necessary S3 buckets (one-off):
- `./automatictester.co.uk-jenkins-config-files.sh`
- `./automatictester.co.uk-jenkins-state.sh`
