# Configure the AWS Provider

variable "bucket-name" {}
variable "keybase-id" {
 default = "dglennie"
}

data "aws_caller_identity" "current" {}
resource "aws_default_vpc" "default" {
    tags {
        Name = "Default VPC"
    }
}

resource "aws_s3_bucket" "icp-terraform-state" {
  # (resource arguments)
   acl    = "private"
    bucket = "${var.bucket-name}"
    lifecycle {
        prevent_destroy = true
    }

}

resource "aws_dynamodb_table" "terraform_statelock" {
  name           = "${var.bucket-name}-tfstate-ddb-table"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_user" "tfstate-user" {
  name="s3-${var.bucket-name}"
}

resource "aws_iam_user_policy" "tfstate-s3-policy" {
  name = "${var.bucket-name}-s3-policy"
  user = "${aws_iam_user.tfstate-user.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket-name}"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket-name}/*"
            ],
            "Effect": "Allow"
        },
        {
           "Action": [
                "dynamodb:GetItem",
                "dynamodb:BatchGetItem",
                "dynamodb:Query",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:BatchWriteItem"
            ],
           "Resource": [
              "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.terraform_statelock.name}"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "tfstate-user-key" {
  user = "${aws_iam_user.tfstate-user.name}"
  pgp_key = "keybase:${var.keybase-id}"
}


output "secret_key" {
  value= "${aws_iam_access_key.tfstate-user-key.encrypted_secret}"
  sensitive=true
}

output "access_key" {
  value= "${aws_iam_access_key.tfstate-user-key.id}"
}

output "lock_table" {
  value= "${aws_dynamodb_table.terraform_statelock.name}"
}

