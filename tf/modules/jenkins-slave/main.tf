resource "aws_iam_role" "jenkins_slave_role" {
  name                 = "JenkinsSlave"
  assume_role_policy   = file("iam-policy/assume-role-policy.json")
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

resource "aws_iam_role_policy_attachment" "s3_full_access_policy_attachment" {
  role                 = aws_iam_role.jenkins_slave_role.name
  policy_arn           = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_full_access_policy_attachment" {
  role                 = aws_iam_role.jenkins_slave_role.name
  policy_arn           = "arn:aws:iam::aws:policy/AWSLambdaFullAccess"
}

resource "aws_iam_role_policy_attachment" "manage_iam_through_tf_policy_attachment" {
  role                 = aws_iam_role.jenkins_slave_role.name
  policy_arn           = aws_iam_policy.jenkins_slave_manage_iam_through_tf_policy.arn
}

resource "aws_iam_instance_profile" "jenkins_slave_instance_profile" {
  name                 = "JenkinsSlave"
  role                 = aws_iam_role.jenkins_slave_role.name
}
