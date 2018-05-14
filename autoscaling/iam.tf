resource "aws_iam_role_policy_attachment" "icp_iam_cloudwatchlogsfullaccess" {
  count = "${var.enabled && var.existing_lambda_iam_instance_profile_name == "" ? 1 : 0}"
  role = "${aws_iam_role.icp_lambda_iam_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role" "icp_lambda_iam_role" {
  count = "${var.enabled && var.existing_lambda_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.lambda_iam_role_name}-${var.cluster_id}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "icp_lambda_iam_role_policy" {
  count = "${var.enabled && var.existing_lambda_iam_instance_profile_name == "" ? 1 : 0}"
  name = "${var.lambda_iam_role_name}-policy-${var.cluster_id}"
  role = "${aws_iam_role.icp_lambda_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["autoscaling:CompleteLifecycleAction"],
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "icp_lambda_iam_s3fullaccess" {
  count = "${var.enabled && var.existing_lambda_iam_instance_profile_name == "" ? 1 : 0}"
  role = "${aws_iam_role.icp_lambda_iam_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
