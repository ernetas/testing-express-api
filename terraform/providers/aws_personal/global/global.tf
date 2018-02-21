variable "name"              { }
variable "region"            { }
variable "public_key_path"   { }

terraform {
/*  backend "s3" {
    bucket = "ernestas2-terraform"
    key    = "global/terraform.tfstate"
    region = "us-east-1"
  }
*/
  backend "local" {
   path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "personal" {
    bucket = "personal-config"
    acl = "private"
    

    tags {
        Name = "personal-config"
    }
}

module "circleci_aws_ecr" {
  source = "../../../modules/aws_personal/util/iam"

  name       = "circleci-aws-ecr-iam"
  users      = "circleci-api"
  policy     = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Effect": "Allow",
		"Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "ecs:*",
                "ecr:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "dynamodb:*",
                "rds:*",
                "sqs:*",
                "logs:*",
                "iam:GetPolicyVersion",
                "iam:GetRole",
                "iam:PassRole",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfiles",
                "iam:ListRoles",
                "iam:ListServerCertificates",
                "acm:DescribeCertificate",
                "acm:ListCertificates",
                "codebuild:CreateProject",
                "codebuild:DeleteProject",
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
		],
		"Resource": "*"
	},
  {
    "Sid": "Stmt1392016154000",
    "Effect": "Allow",
    "Action": [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ],
    "Resource": [
      "arn:aws:s3:::${aws_s3_bucket.personal.id}/*"
    ]
  },
  {
    "Sid": "AllowRootAndHomeListingOfBucket",
    "Action": ["s3:ListBucket"],
    "Effect": "Allow",
    "Resource": ["arn:aws:s3:::${aws_s3_bucket.personal.id}"],
    "Condition":{"StringLike":{"s3:prefix":["*"]}}
  }]
}
EOF
}

//
// Policies
//

resource "aws_iam_policy" "iam_policy" {
    name = "ecs-api"
    path = "/"
    description = "allows instance to work with ECS"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEbAuth",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "AllowPull",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ecr:us-west-1:232157311879:repository/ernestasapi"
      ],
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage"
      ]
    }
  ]
}
EOF
}

//
// Roles
//

resource "aws_iam_role" "iam_role" {
    lifecycle { create_before_destroy = true }
    name = "ecs-api"
    assume_role_policy = <<EOF
{
"Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

//
// Attach policy to roles
//

resource "aws_iam_policy_attachment" "iam_policy_attachment" {
  name = "ecs-api"
  roles = [
    "${aws_iam_role.iam_role.name}"
  ]
  policy_arn = "${aws_iam_policy.iam_policy.arn}"
}

//
// Create an istance profile from a role
//

resource "aws_iam_instance_profile" "iam_instance_profile" {
  lifecycle { create_before_destroy = true }
  name = "ecs-api"
  role = "${aws_iam_role.iam_role.name}"
}

resource "aws_key_pair" "key" {
  lifecycle { create_before_destroy = true }
  key_name   = "key"
  public_key = "${file(var.public_key_path)}"
}

output "key_name"             { value = "${aws_key_pair.key.key_name}" }
output "circleci_access_ids"  { value = "${module.circleci_aws_ecr.access_ids}" }
output "circleci_secret_keys" { value = "${module.circleci_aws_ecr.secret_keys}" }

