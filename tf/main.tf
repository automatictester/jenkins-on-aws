terraform {
  backend "s3" {
    bucket = "automatictester.co.uk-jenkins-state"
    key    = "jenkins.tfstate"
    region = "eu-west-2"
  }
}

provider "aws" {
  region   = "eu-west-2"
}


module "jenkins_master" {
  source   = "./modules/jenkins-master"
}

module "jenkins_slave" {
  source   = "./modules/jenkins-slave"
}

module "packer" {
  source   = "./modules/packer"
}
