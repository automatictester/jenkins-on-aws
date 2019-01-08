terraform {
  backend "s3" {
    bucket             = "automatictester.co.uk-jenkins-state"
    key                = "jenkins.tfstate"
    region             = "eu-west-2"
  }
}

provider "aws" {
  region               = "eu-west-2"
}

resource "aws_iam_role" "jenkins_master_role" {
  name                 = "JenkinsMaster"
  assume_role_policy   = "${file("iam-policy/assume-role-policy.json")}"
}

resource "aws_iam_role" "jenkins_slave_role" {
  name                 = "JenkinsSlave"
  assume_role_policy   = "${file("iam-policy/assume-role-policy.json")}"
}

resource "aws_iam_policy" "pass_role_policy" {
  name                 = "PassRole"
  path                 = "/"
  policy               = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "jenkins_master_manage_ec2_slaves_policy" {
  name                 = "JenkinsMasterManageEC2Slaves"
  path                 = "/"
  policy               = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:GetConsoleOutput",
                "ec2:RunInstances",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DescribeInstances",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeRegions",
                "ec2:DescribeImages",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "jenkins_slave_manage_iam_through_tf_policy" {
  name                 = "JenkinsSlaveManageIAMThroughTF"
  path                 = "/"
  policy               = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreatePolicy",
                "iam:DetachRolePolicy",
                "iam:ListPolicyVersions",
                "iam:ListAttachedRolePolicies",
                "iam:UpdateRoleDescription",
                "iam:DeletePolicy",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:UpdateRole",
                "iam:AttachRolePolicy",
                "iam:CreatePolicyVersion"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "pass_role_policy_attachment" {
  role                 = "${aws_iam_role.jenkins_master_role.name}"
  policy_arn           = "${aws_iam_policy.pass_role_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "manage_ec2_slaves_policy_attachment" {
  role                 = "${aws_iam_role.jenkins_master_role.name}"
  policy_arn           = "${aws_iam_policy.jenkins_master_manage_ec2_slaves_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "s3_full_access_policy_attachment" {
  role                 = "${aws_iam_role.jenkins_slave_role.name}"
  policy_arn           = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_full_access_policy_attachment" {
  role                 = "${aws_iam_role.jenkins_slave_role.name}"
  policy_arn           = "arn:aws:iam::aws:policy/AWSLambdaFullAccess"
}

resource "aws_iam_role_policy_attachment" "manage_iam_through_tf_policy_attachment" {
  role                 = "${aws_iam_role.jenkins_slave_role.name}"
  policy_arn           = "${aws_iam_policy.jenkins_slave_manage_iam_through_tf_policy.arn}"
}

resource "aws_iam_instance_profile" "jenkins_master_instance_profile" {
  name                 = "JenkinsMaster"
  role                 = "${aws_iam_role.jenkins_master_role.name}"
}

resource "aws_iam_instance_profile" "jenkins_slave_instance_profile" {
  name                 = "JenkinsSlave"
  role                 = "${aws_iam_role.jenkins_slave_role.name}"
}
