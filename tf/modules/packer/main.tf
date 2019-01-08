terraform {
  backend "s3" {
    bucket             = "automatictester.co.uk-packer-state"
    key                = "packer.tfstate"
    region             = "eu-west-2"
  }
}

provider "aws" {
  region               = "eu-west-2"
}

resource "aws_iam_role" "packer_role" {
  name                 = "Packer"
  assume_role_policy   = "${file("iam-policy/assume-role-policy.json")}"
}

resource "aws_iam_policy" "s3_get_jenkins_config_files_policy" {
  name                 = "GetJenkinsConfigFiles"
  path                 = "/"
  description          = "Get config files for Jenkins Master and Slave AMIs from S3"
  policy               = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.s3_bucket_jenkins_config_files}/*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ec2_attach_detach_volume_policy" {
  name                 = "EC2VolumeAttachDetach"
  path                 = "/"
  description          = "Attach and detach EC2 volumes"
  policy               = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DetachVolume",
                "ec2:AttachVolume",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeVolumes"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_get_config_files_policy_attachment" {
  role                 = "${aws_iam_role.packer_role.name}"
  policy_arn           = "${aws_iam_policy.s3_get_jenkins_config_files_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "ec2_attach_detach_volume_policy_attachment" {
  role                 = "${aws_iam_role.packer_role.name}"
  policy_arn           = "${aws_iam_policy.ec2_attach_detach_volume_policy.arn}"
}

resource "aws_iam_instance_profile" "packer_instance_profile" {
  name                 = "Packer"
  role                 = "${aws_iam_role.packer_role.name}"
}
