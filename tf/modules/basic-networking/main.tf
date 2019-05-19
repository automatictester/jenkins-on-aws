resource "aws_vpc" "jenkins-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "Jenkins VPC"
  }
}

resource "aws_internet_gateway" "jenkins-vpc-gw" {
  vpc_id = "${aws_vpc.jenkins-vpc.id}"

  tags {
    Name = "Jenkins IGW"
  }
}

resource "aws_route_table" "jenkins-vpc-rt" {
  vpc_id = "${aws_vpc.jenkins-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.jenkins-vpc-gw.id}"
  }

  tags {
    Name = "Jenkins RT"
  }
}

resource "aws_subnet" "jenkins-vpc-subnet" {
  vpc_id = "${aws_vpc.jenkins-vpc.id}"
  cidr_block = "10.0.0.0/20"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true

  tags {
    Name = "Jenkins Subnet"
  }
}

resource "aws_route_table_association" "rt-association" {
  subnet_id      = "${aws_subnet.jenkins-vpc-subnet.id}"
  route_table_id = "${aws_route_table.jenkins-vpc-rt.id}"
}

resource "aws_security_group" "jenkins_farm" {
  name = "Jenkins Farm"
  description = "Allow full connectivity between Jenkins Master and Slaves"
  vpc_id = "${aws_vpc.jenkins-vpc.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags {
    Name = "Jenkins Farm"
  }
}

resource "aws_security_group" "jenkins_master" {
  name = "Jenkins Master"
  description = "SSH and Jenkins HTTPS from my public IP only"
  vpc_id = "${aws_vpc.jenkins-vpc.id}"

  tags {
    Name = "Jenkins Master"
  }
}

resource "aws_security_group_rule" "allow_ingress_ssh" {
  security_group_id = "${aws_security_group.jenkins_master.id}"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [
    "37.120.156.143/32"
  ]
}

resource "aws_security_group_rule" "allow_ingress_https" {
  security_group_id = "${aws_security_group.jenkins_master.id}"
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = [
    "37.120.156.143/32"
  ]
}

resource "aws_security_group_rule" "allow_egress_allow_all" {
  security_group_id = "${aws_security_group.jenkins_master.id}"
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
}
