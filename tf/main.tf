terraform {
  backend "s3" {
    bucket  = "automatictester.co.uk-jenkins-state"
    key     = "jenkins.tfstate"
    region  = "eu-west-2"
  }
}

provider "aws" {
  region    = "eu-west-2"
}

variable "public_ip" {}

module "basic_networking" {
  source    = "./modules/basic-networking"
  public_ip = "${var.public_ip}"
}

module "jenkins_master" {
  source    = "./modules/jenkins-master"
}

module "jenkins_slave" {
  source    = "./modules/jenkins-slave"
}

module "packer" {
  source    = "./modules/packer"
}
